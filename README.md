# Who Pays More and Why?  
## An Analysis of Health Insurance Cost Drivers

🔗 **Interactive Dashboard:**  
https://public.tableau.com/views/HealthCareInsuranceAnalysis_17707752732400/Story1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

---

## 📘 Project Overview

This project explores the key factors that influence health insurance costs using a real insurance dataset. By combining **advanced SQL analysis** with interactive **Tableau visualizations**, the analysis answers five core questions about *who pays more* for insurance and *why*.

The analysis focuses on how insurance charges vary by:
- **Age group**
- **Body Mass Index (BMI) group**
- **Smoking status**
- **Sex**
- **Region**

You can navigate through the story in the Tableau dashboard to see each insight visually.

---

## 🎯 Research Questions

This project addresses the following questions:

1. **Which combination of age group, smoking status, sex, and region has the highest average insurance charges?**  
2. **Within each BMI group, how much higher are the average charges for smokers compared to non-smokers?**  
3. **Which factors (age group, BMI group, smoking status, and region) contribute the most to total insurance costs, and how do their impacts compare?**  
4. **Which types of people are responsible for most of the insurance money being spent (high-cost segments)?**  
5. **For each age group and BMI group, how much more do smokers pay on average compared to non-smokers?**

---

## 🧰 Tools & Techniques

- **SQL** (with advanced window functions and segmentation) to compute aggregated metrics, cost contributions, and comparisons  
- **Tableau** for interactive visual storytelling
- **Data visualization best practices** to highlight key insights clearly

---

## 📊 Key Insights

### 🧠 1. Cost Drivers Overview
- **Obesity emerges as the strongest driver of total insurance cost.**
- Middle-aged groups (especially 40–59) contribute the most.
- Smoking increases individual costs but does not dominate total cost on its own.
- Regional differences exist but are less pronounced compared to age and BMI.

### 💡 2. High-Cost Customer Segments
- A small number of segments are responsible for a **disproportionate share** of total insurance spending.
- Obese subgroups (smokers and non-smokers) in certain age bands dominate the top segments.

### 🚬 3. Smoking and Cost Impact
- Smokers consistently pay **much more than non-smokers** across all BMI categories.
- **Obese smokers** have the highest average charges overall.

### 📈 4. Smoker Premium by Group
- The **smoker premium** (difference between smokers and non-smokers) is largest among obese individuals in all age groups.
- This premium highlights how lifestyle factors (like smoking) interact with BMI and age.

---

## 🗂 Repository Contents

- `/SQL/` — SQL query files used for analysis  
- `/Tableau/` — Tableau workbook and screenshots  
- `README.md` — Project documentation

---

## 📌 How to Use the Dashboard

1. Click the **Tableau Public link** above.
2. Navigate through the story points using the arrows.
3. Review the breakdowns, segment rankings, and smoker impact views.
4. Hover over values for details and percentage contributions.

---

## 📁 Example SQL Concepts Used

- **Window functions** (`AVG() OVER`, `SUM() OVER`)
- **Segment-level aggregation**
- **Percentage contribution calculations**
- **Ranking and ordering for insights**

---

## 🧠 Final Takeaway

> Health insurance costs are driven by a combination of demographic and lifestyle factors. Obesity and smoking consistently emerge as major contributors, and certain age–BMI segments experience disproportionately higher costs. Understanding these patterns can help insurers, policymakers, and individuals make better-informed decisions.

---

