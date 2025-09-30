from diagrams import Diagram, Cluster, Edge
from diagrams.aws.storage import ElasticFileSystemEFS
from diagrams.aws.compute import EC2, Lambda
from diagrams.aws.network import InternetGateway, NATGateway, APIGateway

with Diagram("", show=True, graph_attr={"rankdir": "TB", "nodesep": "1"}):

    igw = InternetGateway("Internet Gateway")
    apigw = APIGateway("API Gateway")

    with Cluster("VPC"):
        lam = Lambda("Webhook handler")

        az1 = Cluster("AZ1")
        az2 = Cluster("AZ2")
        
        with az1:
            with Cluster("Public Subnet"):
                nat1 = NATGateway("NAT Gateway")
            with Cluster("Private Subnet"):
                jenkins1 = EC2("Jenkins")
                with Cluster("Auto Scaling Group"):
                    workers1 = [EC2("Worker"), EC2("Worker"), EC2("Worker")]

        # with az2:
        #     with Cluster("Public Subnet"):
        #         nat2 = NATGateway("NAT Gateway")
        #     with Cluster("Private Subnet"):
        #         jenkins2 = EC2("Jenkins")
        #         with Cluster("Auto Scaling Group"):
        #             workers2 = [EC2("Worker"), EC2("Worker"), EC2("Worker")]

        #efs = ElasticFileSystemEFS("EFS")

    # Connections
    apigw >> lam
    lam >> jenkins1
    #lam >> jenkins2
    #efs >> jenkins1
    #efs >> jenkins2
    igw >> nat1
    #igw >> nat2
    nat1 >> jenkins1 >> workers1
    #nat2 >> jenkins2 >> workers2

