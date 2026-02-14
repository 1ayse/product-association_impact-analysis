# Association & Disassociation Sales Analysis

## Purpose
Analyze sales performance 7 days before and after product association changes.

---

## Data Sources (Anonymized)

- prod.skc_snapshot → Historical SKC – SPU mapping snapshots  
- prod.skc_master → Master product catalog reference table  
- prod.spu_attr_snapshot → Product attribute history (multicolor flag tracking)  
- prod.sales_daily → Daily sales & exposure performance table  
- temp.priority_list → Priority SKC selection list  

---

## Key SQL Functions Used

### Window Functions
- LAG() → Detect previous state changes (SPU change, flag change)

### Date Functions
- parse_datetime() → Convert string date to datetime
- date_add() → Shift date windows (±7 days logic)
- date_format() → Convert datetime back to string format (yyyyMMdd)

### Aggregation
- SUM() → Sales & exposure aggregation
- MIN() → Detect first association / disassociation date

---

## Logic

1. Detect SPU association change using window function comparison  
2. Detect multicolor flag disassociation using historical attribute snapshots  
3. Calculate 7-day sales & exposure metrics:
   - Pre-association performance  
   - Post-association performance  

---

## Output Metrics

- Goods Count (Sales Volume)  
- Exposure UV (Product Visibility)  

---

## Notes

Table names, schema names, and business-sensitive identifiers have been anonymized.  
Query logic and analytical methodology are preserved for portfolio demonstration purposes.
