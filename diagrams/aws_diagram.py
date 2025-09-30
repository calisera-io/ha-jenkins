from diagrams import Diagram, Edge, Cluster
from diagrams.aws.storage import S3
from custom_nodes import Cloudflare
from diagrams.aws.general import User

with Diagram("Multi-Cloud Hosting", show=True, graph_attr={"splines": "polyline", "rankdir": "LR"}):

    user = User("User")
    
    with Cluster("Cloudflare", graph_attr={"labeljust": "c", "rankdir": "TB"}):
        dns = Cloudflare("DNS")
        cdn = Cloudflare("CDN")

    with Cluster("AWS", graph_attr={"labeljust": "c"}):
        s3 = S3("S3 Bucket")

    # Arrows
    user >> dns
    user >> cdn >> s3
