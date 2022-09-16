Select *
From Coviddb..CovidDeaths$
Order by 3,4

Select location, date, population, total_cases, new_cases, total_deaths
From Coviddb..CovidDeaths$

-- % likelihood of death if you contract covid 
Select 
	location, 
	date, 
	population, 
	total_cases, total_deaths, round((total_deaths/total_cases)*100, 2) as death_percentage
From Coviddb..CovidDeaths$
Where location like '%kenya%'
Order by 1,2

-- % of population that got covid
Select 
	location, 
	date, 
	population, 
	total_cases, 
	population, round((total_cases/population)*100, 1) as covid_percentage
From Coviddb..CovidDeaths$
Where location like '%states%'
Order by 1,2

-- countries with highest infection rate compared to populations
Select 
	location, 
	population, 
	MAX(total_cases) as highest_infection_count, 
	round(MAX(total_cases/population) *100, 2) as percent_population_infected
From Coviddb..CovidDeaths$
Group by location, population
Order by 4 Desc

-- countries with highest death count per population
Select 
	location,
	continent,
	MAX(cast(total_deaths as int)) as total_death_count
From Coviddb..CovidDeaths$
Where continent is not NULL
Group by location, continent
Order by total_death_count desc

-- continents with highest death count
Select 
	location,
	MAX(cast(total_deaths as int)) as total_death_count
From Coviddb..CovidDeaths$
Where (continent Is NULL) And (location Not Like '%income')
Group by location
Order by total_death_count Desc

-- global numbers
Select 
	d.date,
	SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as bigint)) as total_deaths,
	SUM(cast(new_tests as bigint)) as total_tests,
	SUM(cast(new_vaccinations as bigint)) as total_vaccinations
From Coviddb..CovidDeaths$ as d
Inner Join Coviddb..CovidVaccinations$ as v
	On d.iso_code = v.iso_code
Where (d.continent Is Not NULL) Or (d.location Not Like '%income')
Group by d.date
Order by 1,2

-- Rolling Count of new vaccinations
Select 
	d.continent, 
	d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	Sum(convert(bigint, v.new_vaccinations)) Over (Partition by d.location Order by d.location) as rolling_people_vaccinated
From Coviddb..CovidDeaths$ as d
Join Coviddb..CovidVaccinations$ as v
	On (d.location = v.location) And (d.date = v.date)
Where d.continent Is Not NULL
Order by 2,3

-- Use CTE to find vaccinations per population
With pop_vs_vacc (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) as (
Select 
	d.continent, 
	d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	Sum(convert(bigint, v.new_vaccinations)) Over (Partition by d.location Order by d.location) as rolling_people_vaccinated
From Coviddb..CovidDeaths$ as d
Join Coviddb..CovidVaccinations$ as v
	On (d.location = v.location) And (d.date = v.date)
Where d.continent Is Not NULL)

Select *, (rolling_people_vaccinated / population) *100 as percent_people_vaccinated
From pop_vs_vacc

-- Creating a Temp Table
-- Add the first line if you plan on making alterations:
Drop Table If Exists #percentage_population_vaccinated
Create Table #percentage_population_vaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations bigint,
rolling_people_vaccinated numeric
)
Insert into #percentage_population_vaccinated
Select 
	d.continent, 
	d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	Sum(convert(bigint, v.new_vaccinations)) Over (Partition by d.location Order by d.location) as rolling_people_vaccinated
From Coviddb..CovidDeaths$ as d
Join Coviddb..CovidVaccinations$ as v
	On (d.location = v.location) And (d.date = v.date)

Select *, (rolling_people_vaccinated / population) *100 as percent_people_vaccinated
From #percentage_population_vaccinated