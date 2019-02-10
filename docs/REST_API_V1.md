# Notice
This document describes API v1, which is currently still devlopmented.

# Dynamic OverCloud API
Dynamic OverCloud exposes a list of RESTful APIs to perform various actions. All of Dynamic OverCloud's API requests return `JSON`-formatted responses. All API URLs listed in this documentation have the endpoint:

> http://$INTERFACE_PROXY:6125


## API Index
1. [OverCloud Instantiation API](#OverCloud Instantiation API)
2. [OverCloud List API](#OverCloud List API)
3. [OverCloud Delete API](#OverCloud Delete API)


### OverCloud Instantiation API
Dynamic OverCloud Instantiation is to create Dynamic OverCloud depending on the parameters from user


### OverCloud Instantiation API Request Parameters
| Parameter        | Description                                           |
|:-----------------|:------------------------------------------------------|
| provider         | Cloud type (OpenStack, Amazon, heterogeneous          |
| number           | the number of cloud-native clusters                   |
| size             | flavor                                                |
| OpenStack.number | the number of cloud-native clusters (heterogenous)    |
| OpenStack.size   | flavor (heteerogenous)                                |
| OpenStack.post   | DevPost location (yes, no)                            |
| Amazon.number    | the number of cloud-native clusters (heterogenous)    |
| Amazon.size      | flavor (heteerogenous)                                |
| Amazon.post      | DevPost location (yes, no)                            |


_**Example Request**_


```
curl -X POST -H "Content-Type:application/json" -d '{"provider": "heterogeneous", "OpenStack":{"number": "2", "size": "m1.logical", "post": "no"}, "Amazon": {"number": "3", "size": "c5d.2xlarge", "post": "yes"}}' http://$INTERFACE_IP:6125/overclouds
```


## OverCloud Instantiation API Response Parameters
| Parameter        | Description                                           |
|:-----------------|:------------------------------------------------------|
| overcloud_ID     | OverCloud ID                                          |
| devops_post      | DevOps Post IP                                        |
| ssh              | ssh private key                                       |
| logical_cluster  | cloud-native clusters                                 |
| rook_url         | Rook Web URL                                          |
| prometheus_url   | Prometheus Web URL                                    |
| chronograf_url   | chronograf_url                                        |
| weave_url        | WeaveScope Web URL                                    |
| smartx-multiview | smartx-multiview Web URL(SmartX-Multiview is required)|


_**Example Response**_
```json
{ "weave_url": "http://13.124.126.164:32080",
        "devops_post": "13.124.126.164",
        "chronograf_url": "http://13.124.126.164:8888",
        "ssh": "-----BEGIN RSA PRIVATE KEY-----MIIEowIBAAKCAQEAnvKBXqis8H4O6NCg3afVtrVRdzYPJn7aCP9XgYsd3UXy4thgE1GMAFkcdK/ZnU1KIM5iRKWVlsXqSnqL0sZ9Wcs6MXW47Qt6UvWptIH6hM/I5U0ZpLTU1TyeQUvjW5SykQjj+KR3oZf5kBzxr+mRleKLR5hqNdBsFzOf98STv84+ew+mae7CwDAsWANy6uTZySvEMIQSMOBEOFBCQnhoSmgapl6f8eX0BRU51366Fmgg2ppr3cjxBfup25MIf37k6EYctrsInt2Teee95te5rV1f24b92c84MUFJgFAoIP/6cor7Fz1lAHyghiUdgM+AFPp2KMYdmHAiG8wqUh7RTwIDAQABAoIBAFgOOxOI2L4m5/Wc1vHVMDWXP7mOTlhiQEJpyz2uJ25VeRipDJjHPYtX0sbmQOW/UsjX7WLgZP3xSTnXqCyt3/Xl+6g48qkICc154Xlp5LK9NiuqSgGQWLSFb5r3As7SkxZ8WWd/HfN88TogftiYyhnCNq0ESBrmC2vTItUtpzjDlx2T4ZTa+K9IJXgeEZwuNK9u1HgVzNpPs1AMhhdMQSeIiIO7JNM/fWr9Ck12JcUql4r76nS0QwP+zsvcSzNTunrJdAuh8Qpw202Kvj8z1oGuUjc4yoQB1AhlH4WkC1kv21s738MVLWXM1YUVeyC1nUJ2LLVpTRDEpC32rsOVEfkCgYEAzF3eQG7dlb3gT++aezhk2N3BxJG0VJ2eq4I4cccsPBFLsjmVe3JQW3cyuyrc0dWKj2z5nsJIbFTZfYMTIlsy8iNHxYnvk525rx3Gi5A0NrAx5/NZ2p3/TXGHDvmkLE5bgybffdLG1Vv+0EIVFo1mJK01qFxnYFFbLysJreV1vPMCgYEAxxr6nj/aQktODsOcVf0AgjkZH9uo2QYesJSk8iMhL9BD25nSn0nYuw0jPCF0/ahvUF1hIoEqQjMI9A2RdJwLQ5PBybJItobK02nfKJvEFQvfT7vRjBcYZMzDfLVPYEw0/HPmskqHA8PsUHQLZnR9F8zMmeC4GaNTKQDNOgJnQTUCgYBJWLMoiuGqGXCFH+hgqve+wbAGfYisCbnlsiHR6/rbQBXbzEDzAi8G9LvXYuXHxY0qNqFMMkxN3RIFsuJOJU8eijz7D6tVXnlC+TvF4SZsLkZrCfLIvIXhZIplfIFIiYLcijoR7XEBKDhGxEDPTEZJiYTFfQx5DBnezuJ1b/IWswKBgFamzS+WBn0XnO8b/qwFofUKuH5+8KsS2MRszKR82XKfpwipl1qvnt05SH5g6TOD3H4TRbToleWdpGXiic1AJD7SzWHkb3TQkPEVgIOB1wJ52kQvL3FSk9E6tFFP7y2vvNep8VriyIPA/tW8y0FZrR9wiBLoE/dEd2q+6JI4fYuJAoGBAJYLQ29jOkBS5HWLzqFia/y9+BzdLNiImIxj7yTyxopAd7GOZaVUZ5mCYTUIndjQhRl+QSeGtH0fD3gQx5raSBgcfY2vwJpTfeSCTGTEsq5GYn/sqOs7JpgQ3ClCMuCg+NHNka+kgaOZ9NYiUBgozcnrKGeMVHl3LmsSih1Jv1KP-----END RSA PRIVATE KEY-----",
        "prometheus_url": "http://13.124.126.164:30921",
        "rook_url": "http://13.124.126.164:32524",
        "logical_cluster": [
                "13.124.205.161",
                "13.124.248.204",
                "13.124.39.221",
                "13.125.218.219",
                "13.125.93.224"
        ],
        "overcloud_ID": "10fd3e7c-5298-4880-9904-480aace97302",
        "smartx-multiview": "http://192.168.84.20:3006/menu"
        }

```

## OverCloud List API
Dynamic OverCloud List is to show created Dynamic OverClouds


_**Example Request**_


```
curl http://$INTERFACE_IP:6125/overclouds
```

### OverCloud List API Response Parameters
| Parameter        | Description                                           |
|:-----------------|:------------------------------------------------------|
| overcloud_ID     | OverCloud ID                                          |
| tenant_ID        | tenant ID                                             |


_**Example Response**_
```json
{ "overcloud_ID": "10fd3e7c-5298-4880-9904-480aace97302", "tenant_ID": "demo"
}

```


## OverCloud Delete API
Dynamic OverCloud List is to delete created Dynamic OverClouds


### OverCloud Delete API Request Parameters
| Parameter        | Description                                           |
|:-----------------|:------------------------------------------------------|
| overcloud_id     | OverCloud ID                                          |


_**Example Request**_


```
curl -X Delete -H "Content-Type: application/json" -d '{"overcloud_id": "76af94ac-d87e-4f31-b4ad-b6f9ba3067d8"}' http://$INTERFACE_IP:6125/overclouds
```


_**Example Response**_


```
Success
```

