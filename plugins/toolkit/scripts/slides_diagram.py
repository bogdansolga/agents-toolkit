#!/usr/bin/env python3
"""slides_diagram.py: draw box-and-arrow diagrams as native Google Slides shapes.

Why
    A diagram pasted into Slides as an image cannot be edited. This module builds the same
    diagram from native shapes (rounded boxes, dashed frames, text boxes, straight lines with
    arrowheads), so every box, label and arrow stays editable in Slides.

What it produces
    A list of Slides API `batchUpdate` request objects. Nothing is sent from here; the caller
    passes the list to the API, for example with the toolkit's Slides CLI:

        python3 my_diagram.py my-key SLIDE_OBJECT_ID > requests.json
        gslides.sh batch PRESENTATION_ID "$(cat requests.json)"

How to use it
    1. Write a spec: a function that takes a `Slide` and calls `box`, `frame`, `label` and
       `path` on it. `slides_diagram_example.py` is a complete one.
    2. Run the spec for an existing slide (its objectId), then send the requests.
    3. To redraw, delete the slide's page elements whose objectId starts with "<key>_n"
       and send the new requests. The rest of the slide (title, logo) is left alone.

Coordinate system
    All positions and sizes are in pixels of a 1080 x 608 render of a 16:9 slide
    (the default 12,191,675 x 6,858,000 EMU page). Measuring a diagram on a 1080px-wide PDF
    render of the slide gives the numbers directly. `K` converts pixels to EMU.

Type scale
    The defaults below were tuned on a real deck: box titles 12pt bold at 150% line spacing;
    box text 10pt at 100% when it spans several lines, 115% when it fits on one; tags 12pt
    bold; edge labels 10pt. Pass `tsize`, `ssize` or `lsize` to override one element.

Known Slides behaviour this module works around
    - The corner radius of ROUND_RECTANGLE scales with the box, so large boxes look oval.
      Boxes taller than 150px and all frames are drawn as plain rectangles.
    - A line's size must be non-zero in both directions; a horizontal or vertical segment
      gets a 0.01px extent on its flat axis.
    - Lines that go left or up are drawn with a negative scale, so the arrowhead stays at the
      segment's end point.

Requires Python 3.8+ and nothing outside the standard library.
"""

# Pixels to EMU: the slide is 12,191,675 EMU wide and the coordinate system is 1080px wide.
K = 12191675 / 1080

# Named styles: (fill colour, outline colour) as hex RGB. A None fill draws an empty outline.
# The palette follows draw.io's defaults, so diagrams moved from draw.io keep their colours.
C = {
    "blue": ("DAE8FC", "6C8EBF"),        # people, users
    "orange": ("FFE6CC", "D79B00"),      # external systems
    "purple": ("E1D5E7", "9673A6"),      # the system being described
    "green": ("D5E8D4", "82B366"),       # data stores
    "yellow": ("FFF2CC", "D6B656"),      # configuration, files
    "white": ("FFFFFF", "9673A6"),       # components inside a container
    "pale_purple": ("F8F6FC", "9673A6"), # frame background
    "pale_blue": ("F5F8FC", "6C8EBF"),   # frame background
    "none": (None, "999999"),            # outline only
}

# Text colours (title, secondary text) and the colour of every line.
DARK, GREY, LINE = "1A1A1A", "555555", "666666"

# Default font sizes in points: box title, box text, tag (e.g. a milestone badge), edge label.
TITLE_PT, TEXT_PT, TAG_PT, EDGE_PT = 12, 10, 12, 10

# Default line spacing in percent: box title, multi-line box text, single-line box text.
TITLE_LS, TEXT_LS_MULTI, TEXT_LS_SINGLE = 150, 100, 115

# Boxes taller than this (px) are drawn square-cornered; see "Known Slides behaviour".
ROUND_MAX_HEIGHT = 150

# Minimum width (px) of a tag, so short tags such as "M2" line up from box to box.
TAG_MIN_WIDTH = 42.4


def rgb(hex_colour):
    """Convert "RRGGBB" to the Slides API RgbColor object (channels from 0 to 1)."""
    return {
        "red": int(hex_colour[0:2], 16) / 255,
        "green": int(hex_colour[2:4], 16) / 255,
        "blue": int(hex_colour[4:6], 16) / 255,
    }


def label_width(text, size):
    """Estimate the width (px) a one-line label needs at `size` points.

    Uses an average Arial glyph width of 0.55 em plus 22px for the text box's default
    insets. The estimate errs wide, so labels do not wrap onto a second line.
    """
    return len(text) * size * 0.55 + 22


def utf16_len(text):
    """Length of `text` in UTF-16 code units, which is how the Slides API counts indices."""
    return len(text.encode("utf-16-le")) // 2


class Slide:
    """Collects the requests that draw one diagram on one existing slide.

    key   short prefix for every object id this diagram creates, e.g. "ctx"; ids come out as
          "ctx_n001", "ctx_n002", ... Object ids must be unique in the presentation, so use
          a different key for each slide.
    page  objectId of the slide to draw on.

    After the drawing calls, `reqs` holds the batchUpdate requests in order.
    """

    def __init__(self, key, page):
        self.key = key
        self.page = page
        self.n = 0
        self.reqs = []

    # ------------------------------------------------------------------ internals

    def oid(self):
        """Return the next object id for this diagram."""
        self.n += 1
        return f"{self.key}_n{self.n:03d}"

    def _props(self, x, y, w, h):
        """Element properties placing an object at (x, y) with size w x h, all in px."""
        return {
            "pageObjectId": self.page,
            "size": {
                "width": {"magnitude": w * K, "unit": "EMU"},
                "height": {"magnitude": h * K, "unit": "EMU"},
            },
            "transform": {"scaleX": 1, "scaleY": 1, "translateX": x * K, "translateY": y * K, "unit": "EMU"},
        }

    def _text(self, oid, runs, align="CENTER", valign="MIDDLE"):
        """Insert text into shape `oid` and style it.

        runs    list of (text, size_pt, colour_hex, bold, line_spacing_pct); each run becomes
                one paragraph, so a run may itself contain newlines.
        align   horizontal paragraph alignment: START, CENTER or END.
        valign  vertical alignment of the text block in the shape: TOP, MIDDLE or BOTTOM.
        """
        full = "\n".join(r[0] for r in runs)
        if not full:
            return
        self.reqs.append({"insertText": {"objectId": oid, "text": full}})
        # Alignment and zero paragraph gaps apply to the whole shape.
        self.reqs.append({"updateParagraphStyle": {
            "objectId": oid,
            "textRange": {"type": "ALL"},
            "style": {"alignment": align,
                      "spaceAbove": {"magnitude": 0, "unit": "PT"},
                      "spaceBelow": {"magnitude": 0, "unit": "PT"}},
            "fields": "alignment,spaceAbove,spaceBelow"}})
        # Font and line spacing apply per run; `pos` walks the text in UTF-16 units.
        pos = 0
        for text, size, colour, bold, line_spacing in runs:
            end = pos + utf16_len(text)
            if end > pos:
                rng = {"type": "FIXED_RANGE", "startIndex": pos, "endIndex": end}
                self.reqs.append({"updateTextStyle": {
                    "objectId": oid,
                    "textRange": rng,
                    "style": {"fontFamily": "Arial",
                              "fontSize": {"magnitude": size, "unit": "PT"},
                              "bold": bold,
                              "foregroundColor": {"opaqueColor": {"rgbColor": rgb(colour)}}},
                    "fields": "fontFamily,fontSize,bold,foregroundColor"}})
                self.reqs.append({"updateParagraphStyle": {
                    "objectId": oid,
                    "textRange": rng,
                    "style": {"lineSpacing": line_spacing},
                    "fields": "lineSpacing"}})
            pos = end + 1  # skip the newline that joins runs
        self.reqs.append({"updateShapeProperties": {
            "objectId": oid,
            "shapeProperties": {"contentAlignment": valign},
            "fields": "contentAlignment"}})

    # ------------------------------------------------------------------ drawing API

    def box(self, x, y, w, h, style, title="", sub="", dashed=False, tag=None, valign="MIDDLE",
            tsize=TITLE_PT, ssize=TEXT_PT, square=False):
        """Draw a filled, outlined box with an optional bold title and secondary text.

        x, y, w, h  position and size in px.
        style       a key of `C`, e.g. "orange" for an external system.
        title       bold first line; empty for a container whose children carry the text.
        sub         secondary text, "\\n" for line breaks.
        dashed      dashed outline, e.g. for scope planned in a later milestone.
        tag         short badge in the top-right corner, e.g. "M2".
        valign      "TOP" for containers, so the title sits above the child boxes.
        tsize       title size in pt; ssize: secondary text size in pt.
        square      force square corners (applied anyway above ROUND_MAX_HEIGHT).

        Returns the box's object id.
        """
        oid = self.oid()
        fill, line = C[style]
        kind = "RECTANGLE" if square or h > ROUND_MAX_HEIGHT else "ROUND_RECTANGLE"
        self.reqs.append({"createShape": {"objectId": oid, "shapeType": kind,
                                          "elementProperties": self._props(x, y, w, h)}})
        props = {"outline": {"outlineFill": {"solidFill": {"color": {"rgbColor": rgb(line)}}},
                             "weight": {"magnitude": 1, "unit": "PT"},
                             "dashStyle": "DASH" if dashed else "SOLID"}}
        fields = "outline.outlineFill.solidFill.color,outline.weight,outline.dashStyle"
        if fill:
            props["shapeBackgroundFill"] = {"solidFill": {"color": {"rgbColor": rgb(fill)}}}
            fields += ",shapeBackgroundFill.solidFill.color"
        else:
            props["shapeBackgroundFill"] = {"propertyState": "NOT_RENDERED"}
            fields += ",shapeBackgroundFill.propertyState"
        self.reqs.append({"updateShapeProperties": {"objectId": oid, "shapeProperties": props, "fields": fields}})

        runs = []
        if title:
            runs.append((title, tsize, DARK, True, TITLE_LS))
        if sub:
            runs.append((sub, ssize, GREY, False, TEXT_LS_MULTI if "\n" in sub else TEXT_LS_SINGLE))
        self._text(oid, runs, valign=valign)

        if tag:
            tw = max(label_width(tag, TAG_PT), TAG_MIN_WIDTH)
            self.label(x + w - tw, y + 5, tw, 12, tag, size=TAG_PT, color=DARK, bold=True, align="END")
        return oid

    def frame(self, x, y, w, h, style, caption, ccolor):
        """Draw a dashed boundary (a deployment, a container's inside) with a caption top-left.

        style   a key of `C`, usually "pale_purple", "pale_blue" or "none".
        caption bold text at the top-left corner; ccolor is its hex colour.

        Draw frames before the boxes inside them: later shapes are painted on top.
        """
        self.box(x, y, w, h, style, dashed=True, square=True)
        self.label(x + 10, y + 4, w - 20, 16, caption, size=8, color=ccolor, bold=True, align="START")

    def label(self, x, y, w, h, text, size=EDGE_PT, color=GREY, bold=False, align="CENTER", bg=None):
        """Draw free text in a text box (no outline).

        bg  hex fill colour behind the text; edge labels use white so they mask the line.

        Returns the text box's object id.
        """
        oid = self.oid()
        self.reqs.append({"createShape": {"objectId": oid, "shapeType": "TEXT_BOX",
                                          "elementProperties": self._props(x, y, w, h)}})
        if bg:
            self.reqs.append({"updateShapeProperties": {
                "objectId": oid,
                "shapeProperties": {"shapeBackgroundFill": {"solidFill": {"color": {"rgbColor": rgb(bg)}}}},
                "fields": "shapeBackgroundFill.solidFill.color"}})
        self._text(oid, [(text, size, color, bold, 100)], align=align)
        return oid

    def path(self, pts, dashed=False, label=None, at=None, lsize=EDGE_PT):
        """Draw a connector through `pts`, with an arrowhead at the last point.

        pts     list of (x, y) points in px; two points make a straight arrow, more make an
                orthogonal or bent route (one straight line per segment).
        dashed  dashed line, e.g. for a flow planned in a later milestone.
        label   optional edge text, drawn on a white box centred on `at` (x, y).
        lsize   label size in pt.

        Lines are not glued to boxes: start and end each route on the box edge it touches.
        """
        for i in range(len(pts) - 1):
            (x1, y1), (x2, y2) = pts[i], pts[i + 1]
            oid = self.oid()
            dx, dy = x2 - x1, y2 - y1
            props = self._props(x1, y1, max(abs(dx), 0.01), max(abs(dy), 0.01))
            # A negative scale flips the line so it runs from (x1, y1) to (x2, y2).
            props["transform"]["scaleX"] = -1 if dx < 0 else 1
            props["transform"]["scaleY"] = -1 if dy < 0 else 1
            self.reqs.append({"createLine": {"objectId": oid, "lineCategory": "STRAIGHT", "elementProperties": props}})
            last = i == len(pts) - 2
            self.reqs.append({"updateLineProperties": {
                "objectId": oid,
                "lineProperties": {"lineFill": {"solidFill": {"color": {"rgbColor": rgb(LINE)}}},
                                   "weight": {"magnitude": 1, "unit": "PT"},
                                   "dashStyle": "DASH" if dashed else "SOLID",
                                   "endArrow": "FILL_ARROW" if last else "NONE"},
                "fields": "lineFill,weight,dashStyle,endArrow"}})
        if label:
            cx, cy = at
            tw = label_width(label, lsize)
            self.label(cx - tw / 2, cy - 7, tw, 14, label, size=lsize, bg="FFFFFF")


def clear_requests(page_elements, key):
    """Return deleteObject requests for every element a previous run of `key` created.

    page_elements  the slide's `pageElements` list, e.g. from `gslides.sh slide ID INDEX`.
    Send these first, then the new drawing requests, to redraw a diagram in place.
    """
    prefix = f"{key}_n"
    return [{"deleteObject": {"objectId": e["objectId"]}}
            for e in page_elements if e.get("objectId", "").startswith(prefix)]
