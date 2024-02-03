-- Number of rows:
SELECT COUNT(*) Total_Rows
FROM covid
-- 365547 rows

-- Number of cols:
SELECT COUNT(*) Total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'covid'
-- 67 cols

SELECT *
FROM covid -- takes a bit of time to executre, at least with my current potato laptop :D 

SELECT *
FROM covid
WHERE location = 'United Kingdom'


-- Creating a temp table with the necessary columns for faster query executions 
DROP TABLE IF EXISTS #COVID_TEMP 
CREATE TABLE #COVID_TEMP(
continent varchar(50),
location varchar(50),
population varchar(50),
date varchar(50),
new_cases varchar(50),
new_deaths varchar(50),
new_vaccinations varchar(50),
hosp_patients varchar(50),
total_deaths varchar(50),
total_cases varchar(50),
total_vaccinations varchar(50)
)

INSERT INTO #COVID_TEMP
SELECT continent, location, population, date, new_cases, new_deaths, new_vaccinations, hosp_patients, total_deaths, total_cases, total_vaccinations
FROM covid
WHERE continent <> ' '
ORDER BY 1, 2

-- checking the Temp table 
SELECT *
FROM #COVID_TEMP

------------------------------------------------------ COVID DEATHS STATS ------------------------------------------------------

-- Showing the list of 20 countries with the highest total deaths - ALL TIME
SELECT TOP(20) location ,MAX(CAST(total_deaths AS FLOAT)) Total_Deaths
FROM #COVID_TEMP
GROUP BY location
ORDER BY 2 DESC

-- Showing the list of continents with the highest total deaths - ALL TIME
SELECT continent ,MAX(CAST(total_deaths AS FLOAT)) Total_Deaths
FROM #COVID_TEMP
GROUP BY continent
ORDER BY 2 DESC

-- Total covid deaths ALL TIME
WITH CTE_TotalDeaths AS(
SELECT location ,MAX(CAST(total_deaths AS FLOAT)) Total_Deaths
FROM #COVID_TEMP
GROUP BY location
)
SELECT SUM(Total_Deaths) Global_Total_Deaths
FROM CTE_TotalDeaths
-- Almost 7M ((

-- Showing the list of 30 countries with the highest death by population percent - ALL TIME
SELECT TOP(30) location, population, MAX(CAST(total_deaths AS FLOAT)) Total_Deathss, (MAX(CAST(total_deaths AS FLOAT)) / CAST(population AS FLOAT))*100 AS death_population_percentage
FROM #COVID_TEMP
GROUP BY location, population
ORDER BY 4 DESC
-- Sadly Peru with .65% death rate / UK with .34% 


------------------------------------------------------ COVID CASES STATS ------------------------------------------------------
-- TOP 30 
SELECT TOP 30 location, MAX(CONVERT(float, total_cases)) Total_cases
FROM #COVID_TEMP
GROUP BY location
ORDER BY Total_cases DESC -- 103M cases in USA so far / 99M China / 45M India / 39M France 

-- Bottom 30
SELECT TOP 30 location, MAX(CONVERT(float, total_cases)) Total_cases
FROM #COVID_TEMP
GROUP BY location
ORDER BY Total_cases -- Obviously we can notice some countries with 0s that's because they're groupped in a 'parent' country,i.e. England Scotland Wales in UK ..etc




------------------------------------------------------ GLOBAL COVID STATS ------------------------------------------------------
---- Note that some rows have exagerrated infalted numbers and may not be 100% accurate to what other trackers/news might say, but the SQL Queries are correct :)

SELECT date, SUM(CONVERT(float, new_cases)) New_Cases, 
			 SUM(CONVERT(float, new_deaths)) New_Deaths, 
			 SUM(CONVERT(float, new_vaccinations)) New_Vaccinations, 
			 ROUND(SUM(CONVERT(float, new_deaths)) * 100.0 / NULLIF(SUM(CONVERT(float, new_cases)), 0), 2) AS newDeath_to_newCases_Ratio
FROM #COVID_TEMP
GROUP BY date
ORDER BY 1

-- The day with the highest new death to new cases ratio
SELECT TOP(10) date, SUM(CONVERT(float, new_cases)) New_Cases, 
			 SUM(CONVERT(float, new_deaths)) New_Deaths, 
			 SUM(CONVERT(float, new_vaccinations)) New_Vaccinations,  
			 ROUND(SUM(CONVERT(float, new_deaths)) * 100.0 / NULLIF(SUM(CONVERT(float, new_cases)), 0), 2) AS newDeath_to_newCases_Ratio
FROM #COVID_TEMP
GROUP BY date
ORDER BY 5 DESC

-- The 10 days with the highest new cases recorded
SELECT TOP(10) date, SUM(CONVERT(float, new_cases)) New_Cases, 
			 SUM(CONVERT(float, new_deaths)) New_Deaths, 
			 SUM(CONVERT(float, new_vaccinations)) New_Vaccinations, 
			 ROUND(SUM(CONVERT(float, new_deaths)) * 100.0 / NULLIF(SUM(CONVERT(float, new_cases)), 0), 2) AS newDeath_to_newCases_Ratio
FROM #COVID_TEMP
GROUP BY date
ORDER BY 2 DESC -- January 2022 and Xmas week in the same year / 8.4M new cases Jan 30th 2022

-- The 10 days with the highest new deaths recorded
SELECT TOP(10) date, SUM(CONVERT(float, new_cases)) New_Cases, 
			 SUM(CONVERT(float, new_deaths)) New_Deaths, 
			 SUM(CONVERT(float, new_vaccinations)) New_Vaccinations, 
			 ROUND(SUM(CONVERT(float, new_deaths)) * 100.0 / NULLIF(SUM(CONVERT(float, new_cases)), 0), 2) AS newDeath_to_newCases_Ratio
FROM #COVID_TEMP
GROUP BY date
ORDER BY 3 DESC -- Dec 2020 and Jan 2021 had the highest / 


-- The 10 days with the highest new vaccinations recorded
SELECT TOP(10) date, SUM(CONVERT(float, new_cases)) New_Cases, 
			 SUM(CONVERT(float, new_deaths)) New_Deaths, 
			 SUM(CONVERT(float, new_vaccinations)) New_Vaccinations, 
			 ROUND(SUM(CONVERT(float, new_deaths)) * 100.0 / NULLIF(SUM(CONVERT(float, new_cases)), 0), 2) AS newDeath_to_newCases_Ratio
FROM #COVID_TEMP
GROUP BY date
ORDER BY 4 DESC -- June, July and August of 2021; +40M vaccinations/day

-- Displaying the top 10 countries who had new vaccinations on the highest vaccination day
SELECT TOP(10) location, CONVERT(float, new_vaccinations) as new_vaccs
FROM #COVID_TEMP
WHERE date = '2021-06-24'
ORDER BY new_vaccs DESC

-- OR with a CTE: 

WITH CTE_Vaccinations AS(
SELECT TOP(1) date, SUM(CONVERT(float, new_cases)) New_Cases, 
			 SUM(CONVERT(float, new_deaths)) New_Deaths, 
			 SUM(CONVERT(float, new_vaccinations)) New_Vaccinations, 
			 ROUND(SUM(CONVERT(float, new_deaths)) * 100.0 / NULLIF(SUM(CONVERT(float, new_cases)), 0), 2) AS newDeath_to_newCases_Ratio
FROM #COVID_TEMP
GROUP BY date
ORDER BY 4 DESC
)


SELECT TOP(10) location, CONVERT(float, new_vaccinations) as new_vaccs
FROM #COVID_TEMP
WHERE date = (SELECT date FROM CTE_Vaccinations)
ORDER BY new_vaccs DESC


-- Top 12 months that had the most new cases in total in China
SELECT TOP 12 location, YEAR(date) as Year, DATEPART(month, date) AS Month, SUM(CONVERT(float, new_cases)) as monthly_new_cases
FROM #COVID_TEMP
WHERE location = 'China'
GROUP BY location, YEAR(date), DATEPART(month, date)
ORDER BY 4 DESC
-- 75 Million new cases in December 2022 :0 :( 

-- Top 12 months that had the most new cases in total in UK
SELECT TOP 12 location, YEAR(date) as Year, DATEPART(month, date) AS Month, SUM(CONVERT(float, new_cases)) as monthly_new_cases
FROM #COVID_TEMP
WHERE location = 'United Kingdom'
GROUP BY location, YEAR(date), DATEPART(month, date)
ORDER BY 4 DESC
-- 3.98 Million new cases in January 2022 :0 :( 

-- Monthly difference of new cases in france
SELECT location, 
       YEAR(date) AS Year, 
       DATEPART(month, date) AS Month, 
       SUM(CONVERT(float, new_cases)) AS monthly_new_cases,
       SUM(CONVERT(float, new_cases)) - LAG(SUM(CONVERT(float, new_cases)), 1, 0) OVER (PARTITION BY location ORDER BY YEAR(date), DATEPART(month, date)) AS monthly_difference
FROM #COVID_TEMP
WHERE location = 'France'
GROUP BY location, YEAR(date), DATEPART(month, date)
ORDER BY 2, 3;

-- Biggest Monthly difference of new cases for 5 of the countries with the most COVID cases / highly populated
SELECT location, 
       YEAR(date) AS Year, 
       DATEPART(month, date) AS Month, 
       SUM(CONVERT(float, new_cases)) AS monthly_new_cases,
       SUM(CONVERT(float, new_cases)) - LAG(SUM(CONVERT(float, new_cases)), 1, 0) OVER (PARTITION BY location ORDER BY YEAR(date), DATEPART(month, date)) AS monthly_difference
FROM #COVID_TEMP
WHERE location IN ('China', 'France', 'United states', 'United Kingdom', 'India', 'Russia')
GROUP BY location, YEAR(date), DATEPART(month, date)
ORDER BY 5 DESC
-- January 2022 was one of the worst months these nations have lived 
