## Dynamic OverCloud Concept and Components


![default](https://user-images.githubusercontent.com/19390594/52537704-d30d4d80-2dac-11e9-91a9-e924a75f93d2.jpg)


Dynamic OverCloud is a specially-arranged razor-thin overlay layer that supports the open-source leveraged service composition in a cloud-agnostic way. Figure (a) illustrates the relationship between Dynamic OverCloud and service layer. Dynamic OverCloud includes several elements to support the MSA-based service composition. Dynamic OverCloud consists of Interface Proxy, Dev+Ops Post, Cloud-native Clusters, Connected DataLake and Visible Fabric. Dynamic OverCloud provides the open-source leveraged service composition when given a containerized microservices pattern that corresponds to the targeted service. Dynamic OverCloud users perform the overall steps of the service composition as placement, stitching and execution based on microservices architecture. Figure (b) shows the internal components that make up Dynamic OverCloud, which are described in detail below.


-	Interface Proxy: Interface Proxy is a communication channel between OverCloud User and UnderCloud. It consists of OverCloud Tower Proxy and UnderCloud Tower Proxy. OverCloud Tower Proxy is a north bound interface for OverCloud Users. It interprets uesr’s requirements and generates information that can understand UnderCloud. It finally delivers them to UnderCloud Tower Proxy. UnderCloud Tower Proxy is a south bound interface for UnderClouds. UnderCloud Tower Proxy communicates with a specific type of clouds to acquire cloud resources. UnderCloud Tower Proxy should be prepared for each cloud. Note that Interface Proxy is not a dynamically generated entity each time, but it is s a shared entity by multiple users.

-	Dev+Ops Post: Dev+Ops Post is an orchestration tower in Dynamic OverCloud. It has several functionalities that support both type of Dev and Ops. It includes orchestration tools for the service composition, Dynamic OverCloud workflows, OverCloud Datastore and OverCloud repository.  Orchestration tools for the service composition include open-source leveraged container orchestration and service workflow orchestration for the Dev part. Dynamic OverCloud workflows are a collection of workflows for dynamic provisioning of Dynamic OverCloud. OverCloud Datastore is an integrated datastore for operational visibility data of Dynamic OverCloud. It stores visibility data from visibility collectors of Visible Fabric to catch the status of Dynamic OverCloud. OverCloud Repository is a repository that stores the instance information of Dynamic OverCloud. For example, when a user deploys Dynamic OverCloud, the related data such as OverCloud ID, specifications of Cloud-native Clusters, Connected DataLake and Visible Fabric are stored to OverCloud repository. These functionalities cooperate with each other to support Dynamic OverCloud.

-	Cloud-native Clusters: Cloud-native Clusters are a collection of logical resources capable of cloud-native computing in Dynamic OverCloud. It provides users with pre-prepared resources for the container-based service composition unlike cloud resources provided by UnderCloud. It can be any type of containers that is compatible with the Cloud-native Computing Foundation (CNCF). Cloud-native Clusters can perform diversified clusters such as 3-tier, IoT-Cloud and HPC/BigData according to principles in cloud-native computing. Dynamic OverCloud utilizes a set of resources called as Cloud-native Clusters to perform the service composition. In the user’s point of view, Cloud-native Clusters is a logical pool of resources supporting containers. 

-	Connected DataLake: Connected DataLake is a collection of integrated datalake where data is freely flexible and connected in Dynamic OverCloud. It has two functionalities. Construction DataLake is a temporal repository for the data that needs to construct Dynamic OverCloud. It should be able to quickly store the data through high-throughput network for dynamic provisioning. Containerized cloud-native DataLake is a logically distributed storage that can be connected with Cloud-native Clusters. It utilizes Container Storage Interface (CSI)-enabled distributed storage tools leveraging container orchestration. User can make use of this DataLake in conjunction with their services during the service composition. This DataLake usually stores the data generated from the user’s service. It supports file, block and object storage depending on user’s requirements. 

-	Visible Fabric: Visible Fabric is a close and delicate inter-connect that can facilitates the support of the multi-layer visibility in resources of Dynamic OverCloud. It requires isolated tenant-aware resources with tightly coupled networking. We assume that these resources are given from UnderCloud since they are out of the control of Dynamic OverCloud. Based on these capabilities, Visible Fabric provides multi-layer visibility understand the overall situation of Dynamic OverCloud with the help of visibility solution. For that, it injects visibility data collectors into Cloud-native Clusters in the form of an agent. Visible Fabric should support dynamic resource-centric visibility rather than fixed topology due to the nature of Dynamic OverCloud. It also should cover the view of workloads that understand the relations of functions for performed services, as well as the view of resources and flow that checks the status of resources and networking in Dynamic OverCloud. 