# 🌍 Causal Spatiotemporal Inference using LSCM

This project explores extensions to the **Latent Space Causal Model (LSCM)** for identifying causal effects in spatio-temporal data—specifically in scenarios with **spillover effects** and **time-lagged treatments**.

Developed during my MSc in Data Science at UCL, this research builds upon the work of Christiansen et al. (2020), which examined the causal link between conflict and deforestation in Colombia.

---

## 🧠 Problem

How can we infer causality in real-world systems where **space and time overlap**, and where treatments at one location or time might influence outcomes elsewhere?

The **Latent Space Causal Model (LSCM)** is a framework primarily designed for **causal spatiotemporal inference**. It is specifically developed to address the challenge of inferring causality in **real-world systems where space and time overlap**. In such complex scenarios, treatments applied at one location or time might influence outcomes elsewhere, and conventional causal inference models are often insufficient.

Key aspects of the LSCM framework include:
- __Problem it Addresses__: The LSCM aims to infer causality in situations involving spillover effects (where an intervention in one place affects outcomes elsewhere) and time-lagged treatments (where the effect of a treatment is not immediate but appears over time).
- __Methodology and Foundation__: The framework applies and extends existing causal theory, including a review of Pearl’s ladder of causality and causal graph theory. Its application involves counterfactual modeling, regression, and causal graph exploration. The LSCM builds upon prior research, such as the work by Christiansen et al. (2020) on conflict and deforestation.
- __Extensions and Enhancements__: The LSCM framework has been extended to be more realistic and generalisable for spatiotemporal data. This includes the introduction of eight novel estimators specifically designed to capture lagged treatment effects and spillovers.

---

## 🔬 Methodology

| Component | Description |
|----------|-------------|
| **Framework** | Latent Space Causal Model (LSCM) |
| **Extensions** | Estimators for lagged treatment effects and spillovers |
| **Data** | Conflict & deforestation data from Colombia |
| **Analysis** | Counterfactual modeling, regression, causal graph exploration |
| **Validation** | Alignment with original findings, statistical consistency checks |

---

## 📉 Results

Although statistical significance was not reached, key results include:
- Confirmed **low explanatory power** of armed conflict on deforestation
- Extended the LSCM framework for more **realistic and generalizable** use in spatiotemporal data
- Proposed clear **avenues for simulation-based power testing** and further causal modeling

---

## 📍 Applications

- Environmental impact modeling (e.g. climate change, conflict zones)
- Healthcare: estimating contagion or policy spillover across regions
- Economic policy: spatial and temporal impact of interventions

---

## 📘 Full Report

> 📄 *Spatiotemporal Causal Inference: Extending the Latent Space Causal Model*  
> MSc Thesis, UCL, Agustín González Pozo, 2023  
> [Link to PDF](./report/UCL_Thesis_LSCM.pdf)

---

## 👤 About Me

I'm Agustín, a Data & AI professional based in London. My interests span causal inference, GenAI, analytics platforms, and AI systems for social impact.

- [LinkedIn](https://www.linkedin.com/in/agustin-gonzalez-pozo)
- [Portfolio](https://github.com/agonzalezp2/agustin-portfolio)

