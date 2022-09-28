select *
from PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 3,4 

--select *
--from PortfolioProject..CovidVaccines
--order by 3,4

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths 
--shows likelihood of dying if you contract covid in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathsPercentage
From PortfolioProject..CovidDeaths
where location like '%king%'
and continent is not null
order by 1, convert(datetime, date, 103)


-- Looking at the Total Cases vs population
-- Shows what perecentage got covid
Select location, date, population, total_cases, (total_cases/population)*100 as DeathsPercentage
From PortfolioProject..CovidDeaths
where location like '%king%'
and continent is not null
order by 1, convert(datetime, date, 103)

-- Looking at countries with highest infection rate compared to population
Select location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentagePopulationInfected
From PortfolioProject..CovidDeaths
where continent is not null
Group by location, population 
order by 4 DESC

-- break down by continent 
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount DESC

--option 2
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is null
Group by location
order by TotalDeathCount DESC

-- Showing Countries with Highest Death Count Per Population
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by location
order by TotalDeathCount DESC

-- showing the contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount DESC


-- Global Numbers 
Select convert(date, date, 103), Sum(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, Sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
order by 1, 2

--overall
Select Sum(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
   Sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
order by 1, 2


-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location,  convert(date, dea.date, 103) date, dea.population, vac.new_people_vaccinated_smoothed
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccines vac
     On dea.location = vac.location 
	 and convert(date, dea.date, 103) = convert(date, vac.date, 103)
Where dea.continent is not null
order by 2,3

--Looking at new vacinations per day
Select dea.continent, dea.location,  convert(date, dea.date, 103) date, dea.population, vac.new_people_vaccinated_smoothed,
SUM(Cast(vac.new_people_vaccinated_smoothed as int)) OVER (partition by dea.location order by dea.location, 
dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccines vac
     On dea.location = vac.location 
	 and convert(date, dea.date, 103) = convert(date, vac.date, 103)
Where dea.continent is not null
order by 2,3

-- USE CTE 

With PopvsVac ( Continent, Location, Date, Population, new_people_vaccinated_smoothed, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location,  convert(date, dea.date, 103), dea.population, vac.new_people_vaccinated_smoothed,
SUM(Cast(vac.new_people_vaccinated_smoothed as int)) OVER (partition by dea.location order by dea.location, 
convert(date, dea.date, 103) ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccines vac
     On dea.location = vac.location 
	 and convert(date, dea.date, 103) = convert(date, vac.date, 103)
Where dea.continent is not null
--order by 2,3
)

Select*, (RollingPeopleVaccinated/Population)*100
From PopvsVac

--Temp Table 
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date Datetime,
Population numeric,
New_people_vaccinated_smoothed numeric,
RollingPeopleVaccinated numeric, 
)

insert into #PercentPopulationVaccinated
Select dea.continent, dea.location,  convert(date, dea.date, 103), dea.population, vac.new_people_vaccinated_smoothed,
SUM(Cast(vac.new_people_vaccinated_smoothed as bigint)) OVER (partition by dea.location order by dea.location, 
convert(date, dea.date, 103) ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccines vac
     On dea.location = vac.location 
	 and convert(date, dea.date, 103) = convert(date, vac.date, 103)
--Where dea.continent is not null
--order by 2,3

Select*, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating view to store data for later visulisation

Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, convert(date, dea.date, 103)date, dea.population, vac.new_people_vaccinated_smoothed,
SUM(Cast(vac.new_people_vaccinated_smoothed as bigint)) OVER (partition by dea.location order by dea.location, 
convert(date, dea.date, 103) ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccines vac
     On dea.location = vac.location 
	 and convert(date, dea.date, 103) = convert(date, vac.date, 103)
Where dea.continent is not null
--order by 2,3

Select *
From PercentPopulationVaccinated

Create view TotalCasesvsTotalDeaths  as
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathsPercentage
From PortfolioProject..CovidDeaths
where location like '%king%'
and continent is not null
--order by 1, convert(datetime, date, 103)

Create View TotalCasesvsPopulation as
Select location, date, population, total_cases, (total_cases/population)*100 as DeathsPercentage
From PortfolioProject..CovidDeaths
where location like '%king%'
and continent is not null
--order by 1, convert(datetime, date, 103)

Create View  CountrieWsithHighestInfectionRateComparedToPopulation as
Select location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentagePopulationInfected
From PortfolioProject..CovidDeaths
where continent is not null
Group by location, population 
--order by 4 DESC

Create View  BreakdownTotalDeathCountByContinent as
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by continent
--order by TotalDeathCount DESC

Create View TotalDeathCountByContinentOpt2 as
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is null
Group by location
--order by TotalDeathCount DESC

Create View CountriesWithHighestDeathPerPopulation as
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by location
--order by TotalDeathCount DESC

Create View ContintentsHighestDeathCountPerPopulation as
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by continent
--order by TotalDeathCount DESC


Create View GlobalNumbers as 
Select convert(date, date, 103)date, Sum(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, Sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
--order by 1, 2

Create View OverallTotalDeath as
Select Sum(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
   Sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
--order by 1, 2

Create View TotalPopulationVsVaccinations as
Select dea.continent, dea.location,  convert(date, dea.date, 103) date, dea.population, vac.new_people_vaccinated_smoothed
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccines vac
     On dea.location = vac.location 
	 and convert(date, dea.date, 103) = convert(date, vac.date, 103)
Where dea.continent is not null
--order by 2,3


