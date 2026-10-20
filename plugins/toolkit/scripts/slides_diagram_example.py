#!/usr/bin/env python3
"""slides_diagram_example.py: a complete diagram spec for slides_diagram.py.

Draws a small C4-style system context (a user, the system, two external systems, one of them
planned for a later milestone) and prints the Slides API requests as JSON.

Usage
    python3 slides_diagram_example.py KEY SLIDE_OBJECT_ID > requests.json
    gslides.sh batch PRESENTATION_ID "$(cat requests.json)"

    KEY prefixes every created object id (KEY_n001, ...); pick one per slide.

To redraw after changing the spec, delete the old elements first. Read the slide with
`gslides.sh slide PRESENTATION_ID INDEX`, pass its pageElements to
slides_diagram.clear_requests(elements, KEY), and send those requests before the new ones.

Copy this file as the starting point for a new diagram: keep the imports and the __main__
block, and replace the body of draw(). Coordinates are px of a 1080 x 608 slide render.
"""
import json
import os
import sys

# The library sits next to this file in the plugin's scripts/ folder.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from slides_diagram import Slide  # noqa: E402


def draw(s):
    """Lay out the example diagram on Slide `s`."""
    # Boxes first; arrows after, so arrowheads are painted on top of box edges.
    s.box(40, 250, 180, 60, "blue", "Customer", "places orders on the web")
    s.box(420, 230, 240, 100, "purple", "Acme Shop", "catalogue · cart · checkout\nweb app and API")
    s.box(840, 180, 200, 60, "orange", "Payment provider", "card payments")
    s.box(840, 320, 200, 60, "orange", "Warehouse system", "stock and shipping", dashed=True, tag="M2")

    # Straight arrow with a label at its midpoint.
    s.path([(220, 280), (420, 280)], label="orders", at=(320, 280))
    # Bent route: right, up, right.
    s.path([(660, 260), (750, 260), (750, 210), (840, 210)], label="charges", at=(750, 235))
    # Dashed flow for later-milestone scope.
    s.path([(660, 300), (750, 300), (750, 350), (840, 350)], dashed=True, label="ships", at=(750, 325))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: slides_diagram_example.py KEY SLIDE_OBJECT_ID")
    slide = Slide(sys.argv[1], sys.argv[2])
    draw(slide)
    json.dump(slide.reqs, sys.stdout)
