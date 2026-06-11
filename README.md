# Fly Emirates Flight Performance Analysis

End-to-end data analytics project on ~1.05M U.S. domestic flight records (Q1 2015). Raw CSV data was cleaned and transformed in MySQL, modelled in Power BI as a three-table star schema, and visualised in a three-page interactive dashboard covering on-time performance, delays, and cancellations.

## Tech Stack
- **MySQL 8.4** — data loading, cleaning, transformation, and the analysis-ready view
- **Power BI** — star-schema data model, DAX measures, and interactive dashboard

## Dataset
- **flights** — ~1,048,575 records (Jan–Mar 2015), one row per flight
- **airlines** — 14 airline code-to-name reference rows
- **airports** — 322 airport reference rows with coordinates

## Pipeline
1. **Load & clean (MySQL):** bulk-loaded the CSVs, handled missing values, decoded coded fields (cancellation reasons, day names, airline codes), formatted times and dates, and added a delay-severity category.
2. **Model (Power BI):** built a star schema with flights as the fact table and airlines/airports as dimensions.
3. **Measure:** defined core KPIs as reusable DAX measures.
4. **Visualise:** a three-page dashboard — Overview, Routes & Airports, and Delay Causes & Cancellations.

## Key KPIs
- **On-Time Performance** — % of operated flights arriving within 15 min of schedule
- **Average Delay** — mean arrival delay (minutes), operated flights only
- **Cancellation Rate** — cancelled flights as % of all scheduled flights

## Key Findings
- On-time performance is ~78% — roughly 1 in 5 flights arrives late.
- Average delay is small (~8 min); the problem is a minority of severe delays.
- Late-aircraft and airline (carrier-controlled) causes drive the most delay minutes.
- Weather is the leading cause of cancellations; security delays are negligible.
- Traffic concentrates on a few corridors (JFK–LAX, LAX–SFO) and hubs (ATL, ORD, DFW).
  

## Repository Structure
├── sql/          # MySQL cleaning & transformation scripts
├── dashboard/    # Power BI .pbix file
├── report/       # Full project report
└── screenshots/  # Dashboard imagespage.
Want me to adjust the README to match your exact filenames, or add the image-embed lines once you know what you'll name the screenshots?
