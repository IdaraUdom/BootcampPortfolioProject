SELECT *
FROM IdaraPortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM IdaraPortfolioProject..CovidVaccinations
--ORDER BY 3,4 

--Selecting the data that will be used in the project
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM IdaraPortfolioProject..CovidDeaths
ORDER BY 1,2

--Looking at Ireland's Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100  DeathPercentage
FROM IdaraPortfolioProject..CovidDeaths
WHERE location like 'Ireland'
ORDER BY 1,2

-- Looking at countries' Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100  DeathPercentage
FROM IdaraPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at continents' Total Cases vs Total Deaths
SELECT continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100  ContinentalDeathPercentage
FROM IdaraPortfolioProject..CovidDeaths
WHERE continent IS  NOT NULL
ORDER BY 1,2

--Comparing countries' Total Cases vs Population
SELECT location, population, total_cases, (total_cases/population)*100 NationalInfectionRate
FROM IdaraPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, total_cases
ORDER BY 1,2

--Comparing continents' Total Cases vs Population
SELECT continent, population, total_cases, (CAST(total_cases AS int)/population)*100 InfectionRate
FROM IdaraPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, population, total_cases
ORDER BY 1,2 

--Comparing countries' Populations vs their Highest Infection Count and Highest Infection Rate
SELECT location, population, MAX (total_cases) HighestInfectedCount, MAX((total_cases/population))*100 HighestInfectionRate
FROM IdaraPortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY HighestInfectionRate desc


--Comparing continents' Populations vs their Highest Infection Count and Highest Infection Rate
SELECT continent, population, MAX (total_cases) HighestInfectedCount, MAX((total_cases/population))*100 HighestInfectionRate
FROM IdaraPortfolioProject..CovidDeaths
GROUP BY continent, population
ORDER BY HighestInfectionRate desc

--Showing countries with the Highest Mortality Rates
SELECT location, MAX(CAST( total_deaths AS int)) AS HighestDeathCount
FROM IdaraPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount desc


--An overview of continents with the Highest Mortality Rates
SELECT location, MAX(CAST( total_deaths AS int)) AS TotalDeathCount
FROM IdaraPortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--Global Numbers of new cases and new deaths per day
SELECT date, SUM (New_cases) NewCases, SUM(Cast(new_deaths as int) ) NewDeaths
FROM IdaraPortfolioProject..CovidDeaths
GROUP BY date
ORDER BY 1

--Global Death Rate of new cases and new deaths per day
SELECT date, SUM (New_cases) TotalCases, SUM(Cast(new_deaths as int) ) TotalDeaths, (SUM (New_cases)/SUM(Cast(new_deaths as int)))*100 NewDeathRate
FROM IdaraPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1

--Storing the global death rate in a view for later visualation
CREATE VIEW GlobalDeathRate AS
SELECT date, SUM (New_cases) TotalCases, SUM(Cast(new_deaths as int) ) TotalDeaths, (SUM (New_cases)/SUM(Cast(new_deaths as int)))*100 NewDeathRate
FROM IdaraPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date

--Looking at countries' total population vs vaccinated with a rolling count
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
	   SUM (CONVERT(int,Vaccinations.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) RollingVaccinationCount
FROM IdaraPortfolioProject..CovidDeaths Deaths
JOIN IdaraPortfolioProject..CovidVaccinations Vaccinations
	ON Deaths.location = Vaccinations.location
	AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NOT NULL
ORDER BY 2,3

-- Generating the percentage of countries' populations that are vaccinated with a rolling count and a CTE
WITH CountryVaccinationStats (Continent, Location, Date, Population, NewVaccinations, RollingVaccinationCount)
as 
(SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
	   SUM (CONVERT(int,Vaccinations.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) RollingVaccinationCount
FROM IdaraPortfolioProject..CovidDeaths Deaths
JOIN IdaraPortfolioProject..CovidVaccinations Vaccinations
	ON Deaths.location = Vaccinations.location
	AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NOT NULL)
SELECT *, RollingVaccinationCount/Population VaccinatedPercentageRollingCount
FROM CountryVaccinationStats

--Creating a view to store CountryVaccinationStats for later visualisation
CREATE VIEW CountryVaccinationStats AS
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
	   SUM (CONVERT(int,Vaccinations.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) RollingVaccinationCount
FROM IdaraPortfolioProject..CovidDeaths Deaths
JOIN IdaraPortfolioProject..CovidVaccinations Vaccinations
	ON Deaths.location = Vaccinations.location
	AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NOT NULL


--Looking at total population vs vaccinated on a continental level
SELECT Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
	   SUM (CONVERT(int,Vaccinations.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) RollingVaccinationCount
FROM IdaraPortfolioProject..CovidDeaths Deaths
JOIN IdaraPortfolioProject..CovidVaccinations Vaccinations
	ON Deaths.location = Vaccinations.location
	AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NULL
ORDER BY 2,3

-- Generating the percentage of populations on a continental level that are vaccinated with a rolling count and a temp table
DROP TABLE IF EXISTS #ContinentalVaccinationStats
CREATE TABLE #ContinentalVaccinationStats
(Location nvarchar (300),
 Date datetime,
 Population numeric,
 Vaccinations numeric, 
 ContinentalRollingVaccinationCount numeric
 )

INSERT INTO  #ContinentalVaccinationStats
SELECT Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
	   SUM (CONVERT(int,Vaccinations.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) ContinentalRollingVaccinationCount
FROM IdaraPortfolioProject..CovidDeaths Deaths
JOIN IdaraPortfolioProject..CovidVaccinations Vaccinations
	ON Deaths.location = Vaccinations.location
	AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NULL
ORDER BY 2,3

SELECT *, ContinentalRollingVaccinationCount/Population VaccinatedPercentageRollingCount
FROM #ContinentalVaccinationStats

--Creating a view to store ContinentalVaccinationStats for later visualisation
CREATE VIEW ContinentalVaccinationStats AS 
SELECT Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
	   SUM (CONVERT(int,Vaccinations.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) ContinentalRollingVaccinationCount
FROM IdaraPortfolioProject..CovidDeaths Deaths
JOIN IdaraPortfolioProject..CovidVaccinations Vaccinations
	ON Deaths.location = Vaccinations.location
	AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NULL