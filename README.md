

# Yammer A/B Testing Analysis: Publisher Update

## Overview
Yammer is a social network for communicating with coworkers. Individuals share documents, updates, and ideas by posting them in groups. 

This project involves an A/B test conducted by Yammer on its core feature, the "publisher" module, where users compose messages. The goal was to assess the redesigned version of the publisher and its impact on user engagement, with a particular focus on existing users. The analysis examines multiple engagement metrics to understand user behavior changes and validate the initial observation of a higher message posting rate in the treatment group.

**Period:** June 1 to June 30  
**Groups:**
- **Control Group:** Users who interacted with the old publisher version.
- **Treatment Group:** Users who interacted with the new publisher version.

## Data Sources
The analysis uses data from:
- **Yammer Experiments:** Details on experiment groups, user IDs, and timestamps.
- **Yammer Users:** Contains user profiles, including activation dates to help differentiate new and existing users.
- **Yammer Events:** Logs various user actions like logins and engagement events (e.g., message posts).

## Objectives
The primary objective of this A/B test analysis is to examine user engagement metrics beyond the general observation of increased message posting. By focusing on existing users specifically, the analysis seeks to answer:
1. Whether the new publisher leads to sustained engagement among existing users.
2. How other engagement metrics (like login frequency and engagement days) compare across control and treatment groups.

## Hypothesis
- **Null Hypothesis:** The new publisher does not significantly impact engagement metrics for existing users.
- **Alternative Hypothesis:** The new publisher significantly increases engagement metrics for existing users.

## Analysis Steps

### 1. Cohort Analysis: Segmenting New and Existing Users
Separate users into new (activated after June 1) and existing (activated before June 1) cohorts to focus on engagement among existing users.

### 2. Login Validation
**Step-by-Step Process:**
- **Data Extraction:** Retrieve data from the experiment, user, and event tables. Calculate the number of login events for each user.
- **Aggregation:** Calculate summary statistics for each experiment group (e.g., average, total, standard deviation).
- **Comparison:** Compare login metrics between control and treatment groups for existing users:
  - Average login events
  - Total login events
- **Statistical Testing:** Compute the t-statistic and p-value to determine the significance of observed differences.

### 3. Days Engaged Analysis
**Steps:**
- **Metric Calculation:** Calculate distinct engagement days per user to assess active days.
- **Aggregation:** Compute statistics on days engaged within control and treatment groups.
- **Comparison:** Calculate t-statistics and p-values to compare engagement days across groups for existing users.

### 4. Message Posting by Existing Users
**Steps:**
- **Metric Calculation:** Count messages posted by each existing user.
- **Aggregation:** Compute average, total, and standard deviation of posts for both groups.
- **Statistical Testing:** Test for significant differences in posting rates among existing users between control and treatment groups.

## Key Findings
- **Login Frequency:** Login events were found to increase among existing users in the treatment group, though further statistical testing was required to confirm the significance.
- **Days Engaged:** Existing users in the treatment group showed an increase in average engaged days, suggesting more consistent usage of the platform.
- **Message Posting:** Existing users in the treatment group demonstrated a notable increase in message posts, validating the initial observation within this cohort.

## Statistical Results
| Metric             | Control Group | Treatment Group | t_stat     | P-Value |
|--------------------|---------------|-----------------|------------|---------|
| Average Logins     | 3.3           | 4.1             | 6.1        | 0       |
| Avg. Engaged Days  | 3.0           | 3.6             | 5.4      | 8.6e-8    |
| Avg. Messages Posted (only existing users)   | 2.9           | 4.1             | 5.5       | 3.2e-8    |

## Interpretation
The new publisher module led to a statistically significant increase in login frequency, days engaged, and message posting among existing users in the treatment group, suggesting that the redesign positively impacted engagement within this cohort. These findings provide evidence supporting further adoption of the new publisher.



