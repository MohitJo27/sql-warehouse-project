# Data Catalog for Gold Layer

## Overview

The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of dimension tables and fact tables for specific business metrics.

---

## 1. gold.dim_customers

**Purpose:** Stores customer details enriched with demographic and geographic data.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| customer_key | INT | Surrogate key uniquely identifying each customer record in the dimension table. |
| customer_id | INT | Unique numerical identifier assigned to each customer. |
| customer_number | NVARCHAR(50) | Alphanumeric identifier representing the customer, used for tracking and referencing. |
| first_name | NVARCHAR(50) | The customer's first name, as recorded in the system. |
| last_name | NVARCHAR(50) | The customer's last name or family name. |
| country | NVARCHAR(50) | The country of residence for the customer (e.g., 'Australia'). |
| marital_status | NVARCHAR(50) | The marital status of the customer (e.g., 'Married', 'Single'). |
| gender | NVARCHAR(50) | The gender of the customer (e.g., 'Male', 'Female', 'n/a'). |
| birthdate | DATE | The date of birth of the customer, formatted as YYYY-MM-DD (e.g., 1971-10-06). |
| create_date | DATE | The date and time when the customer record was created in the system. |

---

## 2. gold.dim_products

**Purpose:** Provides information about the products and their attributes.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| product_key | INT | Surrogate key uniquely identifying each product record in the product dimension table. |
| product_id | INT | A unique identifier assigned to the product for internal tracking and referencing. |
| product_number | NVARCHAR(50) | A structured alphanumeric code representing the product, often used for categorization or inventory. |
| product_name | NVARCHAR(50) | Descriptive name of the product, including key details such as type, color, and size. |
| category_id | NVARCHAR(50) | A unique identifier for the product's category, linking to its high-level classification. |
| category | NVARCHAR(50) | The broader classification of the product (e.g., Bikes, Components) to group related items. |
| subcategory | NVARCHAR(50) | A more detailed classification of the product within the category, such as product type. |
| maintenance_required | NVARCHAR(50) | Indicates whether the product requires maintenance (e.g., 'Yes', 'No'). |
| cost | INT | The cost or base price of the product, measured in monetary units. |
| product_line | NVARCHAR(50) | The specific product line or series to which the product belongs (e.g., Road, Mountain). |
| start_date | DATE | The date when the product became available for sale or use. |

---

## 3. gold.fact_sales

**Purpose:** Stores transactional sales data for analytical purposes.

**Columns:**

| Column Name | Data Type | Description |
|---|---|---|
| order_number | NVARCHAR(50) | A unique alphanumeric identifier for each sales order (e.g., 'SO54496'). |
| product_key | INT | Surrogate key linking the order to the product dimension table. |
| customer_key | INT | Surrogate key linking the order to the customer dimension table. |
| order_date | DATE | The date when the order was placed. |
| shipping_date | DATE | The date when the order was shipped to the customer. |
| due_date | DATE | The date when the order payment was due. |
| sales_amount | INT | The total monetary value of the sale for the line item, in whole currency units (e.g., 25). |
| quantity | INT | The number of units of the product ordered for the line item (e.g., 1). |
| price | INT | The price per unit of the product for the line item, in whole currency units (e.g., 25). |

---

## Entity Relationship Summary

```
gold.dim_customers (1) ──< (many) gold.fact_sales (many) >── (1) gold.dim_products
```

- `fact_sales.customer_key` → `dim_customers.customer_key`
- `fact_sales.product_key` → `dim_products.product_key`

---

## Known Issues / Caveats

1. **Surrogate key stability (`customer_key`, `product_key`):** These are generated via `ROW_NUMBER()` over the source data at refresh time. Because the underlying Silver-layer sources are themselves dynamic (auto-refreshing), a customer or product's surrogate key can change value between refreshes. `fact_sales` re-resolves correctly each refresh since it joins on business keys (`product_number`, `customer_id`) rather than the surrogate keys — but any external system or report that persists a surrogate key value directly should account for this.
2. **Column naming note:** In the current DDL, the product dimension's subcategory, maintenance, and cost columns are named `sub_category`, `maintenance`, and `product_cost` respectively — align naming here with the DDL, or update the DDL's `AS` aliases to match this catalog (`subcategory`, `maintenance_required`, `cost`) if this naming is the intended standard.

---

*Last updated: generated from DDL review — update this file whenever the underlying table definitions change.*
