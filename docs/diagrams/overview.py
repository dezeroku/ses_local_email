from diagrams import Cluster, Diagram, Edge
from diagrams.aws.engagement import SES
from diagrams.aws.integration import Eventbridge, SQS
from diagrams.aws.storage import S3
from diagrams.onprem.compute import Server

with Diagram("Overview", show=False, outformat=["png"]):
    with Cluster("AWS"):
        mail_receiver = SES("SES")
        mail_bucket = S3("S3")
        mail_bridge = Eventbridge("Bridge")

        mail_queue = SQS("SQS (FIFO)")

        (
            mail_receiver
            >> mail_bucket
            >> mail_bridge
            >> Edge(label="on ObjectCreated event")
            >> mail_queue
        )
    with Cluster("Bare Metal"):
        poller = Server()

    mail_queue >> Edge(label="long poll (20s) + some sleep") >> poller
