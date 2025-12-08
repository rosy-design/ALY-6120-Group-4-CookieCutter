#### Introduction
<p>The next phase in the CRISP-DM is modeling, which is to create and test models that can help predict customer churn for the fictional online retail company, 2REN (Luna, 2021). 
  The modeling phase helps us connect our prepared and clean data to data-driven insights that could help 2REN improve customer retention and reduce churn rates. </p>

#### Models and Business Problem
<p> For 2REN, their current business problem is customer retention and lowering churn rates. 
  Classification models like logistic regression, decision trees, random forest, and support vector machines would help identify which factors causes churn and predict which customers are likely to leave (Lin, n.d.). 
  Clustering techniques like k-means would segment customers into groups based on behavior patterns, helping to understand which groups show low satisfaction and which segments respond best to coupons. 
  Regression models would predict customer spending patterns and determine customer lifetime values to prioritize retention efforts. 
  These models provide a complete approach to churn prediction for 2REN. </p>
  
#### Model Advantages and Limitations
<p> Each model has pros and cons for churn prediction. Logistic regression is useful because it is fast, interpretable, and explains churn drivers clearly, but it struggles with complex nonlinear patterns (DataCamp, 2024). 
  Decision trees capture nonlinear relationships and are intuitive, though they tend to overfit and can be unstable. 
  Random forests improve accuracy and handle complex patterns, yet they are slower and harder to interpret. 
  SVM creates highly accurate classifiers by separating nonlinear boundaries, but it can be difficult to explain. 
  K-means clustering is fast and helpful for customer segmentation, but it assumes round clusters and offers limited insights. 
  Regression models for customer lifetime value connect attributes to long-term value, but linear approaches may miss nonlinear patterns and can be biased by outliers. </p>

#### Team Collaboration
<p> Because churn prediction requires both technical expertise and strong business context, collaboration between technical specialists and business stakeholders is essential. 
  On the technical side, data scientists and machine learning engineers will design and evaluate models. 
  Data engineers will support this work by preparing high-quality, well-structured data pipelines. 
  Business analysts will help translate analytical insights into actionable business terms. 
  On the business side, input from marketing, customer service, and operations teams is critical, as these groups understand customer behavior, engagement patterns, and operational pain points. 
  HockeyStack (2025) emphasizes that cross-functional collaboration strengthens analytical accuracy by ensuring the models reflect real customer dynamics. </p>

#### Data Quality Issues
<p> Several data-related challenges may occur during modeling. Customer churn datasets typically have significant class unevenness, with many more non-churners than churners, which can cause models to underperform on the minority class. 
  Correlated features may distort model accuracy. Outliers can also bias results. 
  As Ladley (2020) notes, strong data governance and continuous quality checks are crucial to mitigate these risks.</p>

#### Expected Patterns
<p> The models are expected to reveal several key patterns in customer churn behavior. 
  We are looking for which features most strongly predict churn, such as tenure, order frequency, satisfaction scores, and complaint history (Davenport & Harris, 2017). 
  Clustering will identify distinct customer segments at high risk, such as profiles with low satisfaction or specific device usage patterns. 
  We also expect to find behavioral triggers like declining engagement, reduced spending, or lower coupon responsiveness that signal churn risk. 
  These patterns enable targeted retention strategies for at-risk customers (Ladley, 2020). </p>

#### References 
<p> DataCamp. (2024, August 8). Classification in machine learning: An introduction. https://www.datacamp.com/tutorial/classification-machine-learning </p>
<p> Davenport, T. H., & Harris, J. G. (2017). Competing on analytics: The new science of winning (Updated ed.). Harvard Business Review Press. </p>
<p> Géron, A. (2019). Hands-on machine learning with Scikit-Learn and TensorFlow. O'Reilly Media. </p>
<p> Hastie, T., Tibshirani, R., & Friedman, J. (2009). The elements of statistical learning. Springer. </p>
<p> HockeyStack. (2025, June 11). Why cross-functional collaboration is essential for data analysis. https://www.hockeystack.com/blog-posts/why-cross-functional-collaboration-is-essential-for-data-analysis </p>
<p> James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021). An introduction to statistical learning. Springer. </p>
<p> Ladley, J. (2020). Data governance: How to design, deploy, and sustain an effective data governance program (2nd ed.). Academic Press. </p>
<p> Lin, S. (n.d.). 5 data science models for predicting enterprise churn. Reforge. https://www.reforge.com/blog/brief-5-data-science-models-for-predicting-enterprise-churn </p>
<p> Luna, Z. (2021, August 15). CRISP-DM phase 4: Modeling phase. Medium. https://medium.com/analytics-vidhya/crisp-dm-phase-4-modeling-phase-b81f2580ff3 </p>
<p> Maxwell, J. C. (2019). Leadershift. HarperCollins. </p>
