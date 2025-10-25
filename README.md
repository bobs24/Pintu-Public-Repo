# PINTU Data Analyst Take-Home Test

Hi there, thanks for reviewing my project.  
This document explains everything I did and how you can rebuild the database from scratch.

I decided to make this a full, reproducible project using PostgreSQL.  
Instead of just sharing a few scripts, I wanted you to see the whole workflow clearly — from raw data to final, clean tables ready for analysis.

The folder structure is pretty simple and divided into three parts that reflect the process:

* `/1-Data/`: contains the 4 original CSV files you provided.  
* `/2-schemas/`: includes all the SQL scripts to create the database tables. I split this into two groups — one for the raw data (as-is from CSV) and one for the final cleaned model.  
* `/3-transformations/`: this is where all the transformation logic lives. These scripts take the messy raw data and turn it into structured, typed tables.

---
# Section 1

## How to Set It Up (3 Main Steps)

There are just three steps to get everything working.  
If you follow them in order, you’ll end up with a fully loaded and cleaned database.

---

### Step 1: Create the Tables

First, we create the empty tables that define the database structure.  
You can find all the scripts inside the `/2-schemas/` folder.

1. Run `create_raw_tables.sql`.  
   This will build four “raw” tables that match the CSV structure.  
   All columns use `varchar(255)` for now — it’s easier since we’ll clean them later.

2. Run `create_model_tables.sql`.  
   This one creates the final star schema, including `dim_users`, `dim_tokens`, `dim_date`, `fact_trades`, and `fact_p2p_transfers`.  
   These tables already have proper data types (`date`, `numeric`, etc.) and relationships.

---

### Step 2: Load the CSV Data

Now that the raw tables exist, we can load the CSVs into them.  
The fastest way in PostgreSQL is to use the `COPY` command.

You can run these commands in your SQL tool (like DBeaver or psql).  
Just make sure the file paths match your local setup — these examples assume Windows paths.

```sql
copy raw_users 
from 'C:\Users\bobse\Downloads\Personal Code\Test Technical\Pintu\1-Data\raw_users.csv' 
with (format csv, header);

copy raw_tokens 
from 'C:\Users\bobse\Downloads\Personal Code\Test Technical\Pintu\1-Data\raw_tokens.csv' 
with (format csv, header);

copy raw_trades 
from 'C:\Users\bobse\Downloads\Personal Code\Test Technical\Pintu\1-Data\raw_trades.csv' 
with (format csv, header);

copy raw_p2p_transfers 
from 'C:\Users\bobse\Downloads\Personal Code\Test Technical\Pintu\1-Data\raw_p2p_transfers.csv' 
with (format csv, header);
```

### Step 3: Run the Transformations

If your database runs on another system like Docker, Linux, or a remote host, you just need to adjust the path accordingly.

At this point, your raw tables are full of unprocessed data.  
The last step is to clean and structure everything by running the scripts in the 3-transformations folder.

Each script performs a different part of the transformation such as type conversion, trimming messy text, and applying business logic.  
They pull from the raw tables and insert the cleaned data into the dim and fact tables.

#### Run them in this order (some depend on others)

1. load_dim_date.sql  
2. load_dim_users.sql  
3. load_dim_tokens.sql  
4. load_fact_trades.sql — this one needs the dimension tables first  
5. load_fact_p2p_transfers.sql — run this last since it uses fact_trades to calculate the USD value of transfers  

---

And that’s the full setup.  
After these three steps, the database is fully built and ready for analysis.  
Everything should be clean, well structured, and easy to query from here.

---
# Section 2

## My Thinking on Data Lineage & ERD

### Data Lineage

I structured the database in three clear layers to make it easier to trace how data moves and changes from the raw input all the way to the analytics layer. This setup helps ensure transparency, repeatability, and trust in the final results.

1. **Raw Layer (`raw_` tables):**  
   This is the starting point — basically the "landing zone" for all incoming data. The `COPY` command loads the raw CSV files directly into these tables without any modification. Every record is stored as text exactly as it came in, so we always have a true reference of the original data. We don’t modify anything here; it’s our untouched source of truth.

2. **Transformation Layer (`3-transformations` scripts):**  
   This is where most of the data cleaning and business logic happens. The SQL scripts in this layer pull data from the raw tables and fix issues like inconsistent text formatting, incorrect data types, and invalid records (for example, removing `PENDING` trades). They also compute new metrics, such as converting trade amounts into `volume_usd`, so the data becomes more meaningful and ready for analysis.

3. **Analytics Layer (`dim_` and `fact_` tables):**  
   After cleaning, all structured and validated data is inserted into these tables. This forms the star schema that supports analysis and dashboarding. The `fact_` tables store measurable events (like trades or transfers), while the `dim_` tables provide descriptive context (like users or tokens).  
   Analysts and dashboards should only query this layer since it’s optimized for speed, consistency, and clarity.

---

### ERD (Entity Relationship Diagram)

To make the data easy to query and analyze, I used a **star schema design**. This layout keeps everything simple — the fact tables sit at the center containing key metrics, while the dimension tables surround them, providing context such as user details, tokens, or date attributes.  

This structure makes it easy to join data for analysis without overcomplicating queries or hurting performance. It’s also a proven pattern for BI and reporting use cases.

Here’s a quick visual of the model:

![My Data Model ERD](https://raw.githubusercontent.com/bobs24/Pintu-Public-Repo/main/images/ERD.jpg)

---
# Section 3

## My Data Governance Plan

Here's my take on the data governance part.

To be blunt, the leadership team is right to be worried. The PDF mentions duplicate trades, anomalies, and a lack of trust in the dashboards. A dashboard nobody trusts is just a waste of server space.

So, "Data Governance" is just a fancy term for how we're going to fix that. My entire data model is built around this idea. I built the quality checks right into the transformation scripts.

Here's how I'm tackling their specific concerns:

### We Only Count What's Real
**The Problem:** The raw data is full of `PENDING` trades, `CANCELLED` trades, and `FAILED` transfers. If we just sum up the raw tables, our revenue and volume numbers would be completely wrong.

**My Solution:** I built a hard rule right into the code.
* The `fact_trades` script **only** loads data `WHERE status = 'FILLED'`.
* The `fact_p2p_transfers` script **only** loads data `WHERE status = 'SUCCESS'`.

This means when management sees a number for "total volume," it's the *real* volume from *actual, completed* transactions. This is the single most important fix.

### We Stop Duplicates at the Door
**The Problem:** The PDF mentioned "duplicate trades." This is a huge issue. If a $50k trade shows up twice, it throws off all our metrics.

**My Solution:** I've made it impossible for the database to even accept a duplicate.
* The `trade_key` in `fact_trades` and `transfer_key` in `fact_p2p_transfers` are both set as `PRIMARY KEY`s.
* If the raw data feed tries to send the same `trade_id` twice, the database itself will just reject the second one. The `ON CONFLICT DO NOTHING` logic in my script is just an extra layer of safety. This plugs that leak for good.

### We Define "Suspicious"
**The Problem:** The team is worried about "suspiciously high-value" activity. Right now, that's just a gut feeling. We need to turn that gut feeling into a real, automated rule.

**My Solution:** We add a new flag column (like `is_suspicious_flag`) to the `fact_` tables. We'd have to sit down with the compliance team to agree on the logic, but it would be simple, like:
* A **trade** gets flagged as `TRUE` if its `volume_usd` is, say, 25 times bigger than that token's 30-day average.
* A **P2P transfer** gets flagged as `TRUE` if its `amount_usd` is just over a flat number, like $100,000.

This is a huge win for the compliance team. They can just filter for that flag instead of hunting for needles in a haystack.

### We Create a "Single Source of Truth"
**The Problem:** The biggest issue, honestly, is the lack of a "single source of truth." Right now, analysts are probably querying the messy `raw_` tables directly.

**My Solution:** The star schema *is* the solution. We tell everyone: "You are no longer allowed to touch the `raw_` tables. You **only** query the clean `dim_` and `fact_` tables."
* If a number on a dashboard ever looks weird, we can now trace it. I can show the *exact* transformation script that made it and the *exact* raw data it came from. This creates accountability and makes the whole system auditable.