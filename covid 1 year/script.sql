SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3, 4

-- Selecting the data we'll be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
-- Total cases vs Total Deaths
-- Likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United Kingdom'

-- Total cases vs Population 
-- what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United Kingdom'


-- Countries with highest infection rate
SELECT continent, location, population, MAX(total_cases) AS HighestInfectionCount ,MAX((total_cases/population)*100) AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY continent, location, population
ORDER BY InfectedPopulationPercentage DESC
-- Countries with highest death count  
SELECT location, MAX(CAST(total_deaths AS INT)) AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathCount DESC
-- Continents with highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY DeathCount DESC

-- GLOBAL NUMBERS

-- total
SELECT SUM(new_cases) AS newCases, SUM(CAST(new_deaths AS INT)) AS newDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1
-- per day
SELECT date, SUM(new_cases) AS newCases, SUM(CAST(new_deaths AS INT)) AS newDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.continent = vac.continent
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- to know the percentage of the population that are vaccinated 
-- CTE Solution:

WITH PopVacPerc (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/ Population)*100 AS PercentageVaccinated
FROM PopVacPerc
ORDER BY 2, 3 -- can't do ORDER BY inside CTEs



-- TEMP TABLE Solution:
DROP TABLE IF EXISTS #PercentagePeopleVaccinated
CREATE TABLE #PercentagePeopleVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentagePeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/ Population)*100 AS PercentageVaccinated
FROM #PercentagePeopleVaccinated



-- TOP Countries with the most percentage of people vaccinated
WITH PopVacPerc
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT Location, MAX((RollingPeopleVaccinated/ Population)*100) AS PercentageVaccinated
FROM PopVacPerc
GROUP BY Location
ORDER BY PercentageVaccinated DESC


-- Creating a view to store data for later visualisations
DROP VIEW IF EXISTS RollingPeopleVaccinated

CREATE VIEW RollingPeopleVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL



SELECT *
FROM RollingPeopleVaccinated