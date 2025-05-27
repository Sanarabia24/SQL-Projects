
/*

COVID 19 DATA EXPLORATION

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Updating all the empty values to NULL
UPDATE [Portfolio Project]..[Covid Deaths]
SET
  continent = NULLIF(continent, ''),
  location = NULLIF(location, ''),
  total_deaths = NULLIF(total_deaths, ''),
  total_cases = NULLIF(total_cases, '')
WHERE continent = '' OR location = '' OR total_deaths = '' OR total_cases = '';

Select *
From [Portfolio Project]..[Covid Deaths]
Where continent is not NULL
order by 3,4


--Selecting the required data to be used
Select location, FORMAT(CONVERT(DATE, date, 103), 'yyy-MM-dd') as datevalue, total_cases, new_cases, 
total_deaths, population
From [Portfolio Project]..[Covid Deaths]
order by 1,2

--Total Cases vs Total Deaths
--Shows the likelihood of dying by Covid in your country
Select location, FORMAT(CONVERT(DATE, date, 103), 'yyy-MM-dd') as datevalue, total_cases, total_deaths,
(CONVERT (float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) *100 as DeathPercentage
from [Portfolio Project]..[Covid Deaths]
--Where location like '%India%'
order by 1,2

--Total Cases vs Population
--Shows what percentage of population got infected with Covid
Select location, continent, FORMAT(CONVERT(DATE, date, 103), 'yyy-MM-dd') as datevalue, population, total_cases, 
(CONVERT (float, total_cases) / NULLIF(CONVERT(float, Population), 0)) *100 as InfectedPopulationPercentage
from [Portfolio Project]..[Covid Deaths]
--Where location like '%India%'
order by 1,2

--Countries with the highest Covid Infection Rate compared to Population
Select location, continent, population, Max(total_cases) as HighestInfectionCount, 
(CONVERT (float, Max(total_cases)) / NULLIF(CONVERT(float, Population), 0)) *100 as HighestInfectedPopulationPercent
from [Portfolio Project]..[Covid Deaths]
Group by location, continent, population
order by HighestInfectedPopulationPercent desc

--Countries with highest death count per Population
Select location, Max(cast(total_deaths as int)) as TotalDeathCount
From [Portfolio Project]..[Covid Deaths]
Where continent is not NULL
Group by location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

--Showing contintents with the highest death count per population
Select continent, SUM(cast(new_deaths as int)) as TotalDeathCount
from [Portfolio Project]..[Covid Deaths]
where continent!=''
group by continent
order by  TotalDeathCount desc

--Global Numbers
Select SUM(cast(new_cases as int)) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast
(new_deaths as int))/SUM(cast(new_cases as int))*100 as DeathPercentage
from [Portfolio Project]..[Covid Deaths]
Where continent is not NULL

--Global Numbers by Date
Select FORMAT(CONVERT(DATE, date, 103), 'yyy-MM-dd') as datevalue, MAX(CONVERT(float, total_cases)) as TotalCases, 
MAX(CONVERT(float, total_deaths)) as TotalDeaths,
MAX(CONVERT (float, total_deaths)) / NULLIF (MAX(CONVERT(float, total_cases)), 0) *100 as DeathPercentage
from [Portfolio Project]..[Covid Deaths]
Where continent is not NULL
Group by date
order by 1



--Updating all the empty values to NULL
UPDATE [Portfolio Project]..[Covid Vaccinations]
SET
  continent = NULLIF(continent, ''),
  location = NULLIF(location, ''),
  new_vaccinations = NULLIF(new_vaccinations, '')
 WHERE continent = '' OR location = '' OR new_vaccinations = '';


--Combining the two table 
Select *
From [Portfolio Project]..[Covid Deaths] dea
Join [Portfolio Project]..[Covid Vaccinations] vac
On dea.location = vac.location
and TRY_CONVERT(datetime, dea.date) = TRY_CONVERT(datetime, vac.date)


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, TRY_CONVERT(datetime, dea.date), dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, TRY_CONVERT(datetime, dea.date)) as
RollingPeopleVaccinated
From [Portfolio Project]..[Covid Deaths] dea
Join [Portfolio Project]..[Covid Vaccinations] vac
On dea.location = vac.location
and TRY_CONVERT(datetime, dea.date) = TRY_CONVERT(datetime, vac.date)
Where dea.continent is not NULL
order by 2,3


--USE CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(Select dea.continent, dea.location, TRY_CONVERT(datetime, dea.date), dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, TRY_CONVERT(datetime, dea.date)) as
RollingPeopleVaccinated
From [Portfolio Project]..[Covid Deaths] dea
Join [Portfolio Project]..[Covid Vaccinations] vac
On dea.location = vac.location
and TRY_CONVERT(datetime, dea.date) = TRY_CONVERT(datetime, vac.date)
Where dea.continent is not NULL
)

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


--Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PopulationVaccinatedPercent
Create Table #PopulationVaccinatedPercent
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PopulationVaccinatedPercent
Select dea.continent, dea.location, TRY_CONVERT(datetime,dea.date), dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, TRY_CONVERT(datetime,dea.date)) as
RollingPeopleVaccinated
From [Portfolio Project]..[Covid Deaths] dea
Join [Portfolio Project]..[Covid Vaccinations] vac
On dea.location = vac.location
and TRY_CONVERT(datetime,dea.date) = TRY_CONVERT(datetime,vac.date)
Where dea.continent is not NULL

Select *, (RollingPeopleVaccinated/Population)*100
From #PopulationVaccinatedPercent



--Creating View to store data for later visualizations

--View 1: Population Vaccinated Percentage
IF OBJECT_ID('PopulationVaccinatedPercent', 'V') IS NOT NULL
    DROP VIEW PopulationVaccinatedPercent;
GO
Create View PopulationVaccinatedPercent as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as
RollingPeopleVaccinated
From [Portfolio Project]..[Covid Deaths] dea
Join [Portfolio Project]..[Covid Vaccinations] vac
On dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not NULL




