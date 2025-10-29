# README – Rearc Data Quest Submission

**Author:** Harpreet Singh  
**Date:** 10/30/2025  
**AWS Region:** us-east-2  
**S3 Bucket:** rearc-dataquest-harpreet  

---

## 📁 Folder Overview (for quick navigation)

### **Part 1 — BLS Data Ingestion and Sync**  
**Files:**
- `rearc_dataquest_part1.ipynb` – Jupyter Notebook performing BLS data ingestion and synchronization between API and S3.  
- `Link_to_Part1_S3_Files.txt` – Text file containing links to the uploaded CSV files in AWS S3 bucket (`rearc-dataquest-harpreet`), fetched from the BLS API URL.

---

### **Part 2 — DataUSA API Integration**  
**Files:**
- `rearc_dataquest_part2.ipynb` – Jupyter Notebook integrating and fetching data from the DataUSA API.  
- `population_data.json` – JSON file fetched from the DataUSA API URL.  
- `Link_to_Part2_S3_File.txt` – Text file containing the link to the uploaded `population_data.json` file in AWS S3 bucket (`rearc-dataquest-harpreet`).

---

### **Part 3 — Analysis & Results**  
**Files:**
- `rearc_dataquest_part3.ipynb` – Jupyter Notebook performing data analysis on Part 1 and Part 2 datasets.  
- `outputs/` – Folder containing resulting CSV files from the data analysis of Part 1 and Part 2.

**Output Files:**
- `best_year_per_series.csv`  
- `population_mean_std_2013_2018.csv`  
- `prs30006032_q01_with_population.csv`  

**Additional:**
- `Link_to_Part3_S3_Files.txt` – Text file with links to uploaded CSV results in AWS S3 bucket (`rearc-dataquest-harpreet`).

---

### **Part 4 — Terraform Infrastructure**  
**Folder:** `rearc_dataquest_part4_tf/` – Contains all Terraform files for infrastructure automation.

**Key Files:**
- `main.tf`, `variables.tf`, `outputs.tf`, `terraform.lock.hcl`, `myplan`  
- `README.md` – Terraform notes

**Lambda Directories:**
- `lambda_ingest/`  
- `lambda_report/`

---

## 🧠 Documentation
- **File:** `Assistance of AI with Rearc Data Quest challenge.docx`  
  A detailed write-up describing how AI was used in the project.
