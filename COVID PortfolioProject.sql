-- The goal of this project is to explore the public available data related to COVID-19 cases, deaths and vaccinations
-- In order to achieve it, datasets reporting the numbers of daily deaths and vaccinations available at ourworldindata.org have been used

-- First of all, we have to make sure the datasets have been correctly imported

Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3, 4

Select *
From PortfolioProject..CovidVaccinations
order by 3, 4

-- Now it's time to start exploring the data related to cases and deaths

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null -- This WHERE clause is used in order to filter out incomplete aggregated data related to continents, it will prove useful in future explorations
order by 1, 2

-- TOTAL CASES vs TOTAL DEATHS

-- Showing the likelihood of dying if a person contracts Covid

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location = 'Spain' AND continent is not null -- Any specific country can be used as well as a LIKE clause if needed
order by 2

-- Looking at the total cases vs population (% of cases compared to the population)

Select Location, date, total_cases, population, (total_cases/population)*100 as PercentInfectedPopulation
From PortfolioProject..CovidDeaths
where location = 'Spain' AND continent is not null
order by 2

-- Looking at countries with highest infection rates compared to their population

Select Location, population, max(total_cases) AS HighestInfectionCount,
MAX(total_cases/population) * 100 AS PercentInfectedPopulation
FROM PortfolioProject..CovidDeaths
Where continent is not null
group by Location, Population
order by PercentInfectedPopulation desc

-- Let's break things down by continent

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
Where continent is not null
group by continent
order by TotalDeathCount desc

-- Showing the countries with the highest death count

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
Where continent is not null
group by Location
order by TotalDeathCount desc

-- Unfortunately it seems North America's and United States' numbers are the same as they consider the death count to be 576.232, so let's try to fix it
-- We were doing it wrong, as the location column already groups the data in continents

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
Where continent is null
group by Location
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select date, sum(new_cases) as TotalDailyCases, sum(cast(new_deaths as int)) as TotalDailyDeaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as GlobalDeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1, 2

-- In order to get the global raw numbers, we filter out the date

Select sum(new_cases) as TotalDailyCases, sum(cast(new_deaths as int)) as TotalDailyDeaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as GlobalDeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2

-- According to our data, there's roughly a 2,11% chance of dying if covid has been contracted during our timeframe

-- We'll set our sights ont he Covid Vaccinations dataset now

Select *
From PortfolioProject..CovidVaccinations
order by 3, 4

-- Time to join both datasets

Select *
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
order by dea.location, dea.date

-- Looking at TotalPopulation vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null --and dea.location = 'Spain'
order by 2, 3

-- In order to use the rolling % of people vaccinated against its total population we'll use CTE

With PopvsVac (Continent, Location, date, population, new_vaccinations, RollingPeopleVaccinated) as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null --and dea.location = 'Spain'
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- We can also do it via temp table

DROP table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
--where dea.continent is not null --and dea.location = 'Spain'

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated
order by 2, 3

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null --and dea.location = 'Spain'
--order by 2, 3

Select *
From PercentPopulationVaccinated