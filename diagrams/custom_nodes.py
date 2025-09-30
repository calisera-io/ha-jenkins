import os
from diagrams import Node

class Cloudflare(Node):
    _provider = "custom"
    _icon_dir = os.path.join(os.path.dirname(__file__), "resources")
    _icon = "cloudflare.png"
    fontcolor = "white"
    

