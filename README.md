# Product Analysis

We will use MySQL to analyze e-commerce website product data from an online retailer called the Maven Fuzzy Factory.

### Entity Relationship Diagram
<img width="602" alt="Maven ERD" src="https://user-images.githubusercontent.com/70214561/225398444-632ed6c4-3516-406a-a5c5-3c8be87a4989.png">

### Tables
#### We will use 5 tables for our analyses:
`website_sessions` - This table shows each website session access by users, where the traffic is coming from and which source is helping to generate the orders. Records consist of unique website session id, UTM (Urchin Tracking Module) fields, user id, and device type. UTMs tracking parameters used by Google Analytics to track paid marketing activity.

<img width="1395" alt="website_sessions" src="https://user-images.githubusercontent.com/70214561/226083334-da477e34-55c7-40ec-a9b7-ae8a435cc218.png">

`website_pageviews` - This table shows every page viewed for each website session access by users. Records consist of website session id, website pageview id, and pageview url.

<img width="700" alt="website_pageview" src="https://user-images.githubusercontent.com/70214561/226083353-53d7104b-70e6-4576-9e03-d58d088c982f.png">

`orders` - This table shows every order made by customers. Records consist of customers' orders with order id, time when the order is created, website session id, unique user id, primary product id, count of products purchased, price in USD, and cost of goods sold (cogs) in USD.

<img width="1183" alt="orders" src="https://user-images.githubusercontent.com/70214561/226083361-b9280891-8ba4-4060-b0eb-4fabc9fe939d.png">

`order_items` - This table shows every item contained in every order made by customers.

<img width="986" alt="order_items" src="https://user-images.githubusercontent.com/70214561/226083371-80daeea5-be3d-4587-95fa-9662eacdc010.png">

`order_item_refunds` - This table shows every ordered item that is returned and refunded.

<img width="827" alt="order_item_refunds" src="https://user-images.githubusercontent.com/70214561/226083379-68fe7272-6a31-4fbc-bd48-32ad82e0dcbf.png">
