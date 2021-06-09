/*
Queries used for Tableau Project
Source data provided at https://ourworldindata.org/covid-deaths, accessed 5/25/2021
Dashboard visualization can be viewed below.
https://public.tableau.com/app/profile/john.gandy/viz/PortfolioProject2/Dashboard1
*/



-- 1) Checking entire world stats

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From dbo.CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Just a double check based off the data provided
-- The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From dbo.CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2) Sort by continent, order by largest death count

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From dbo.CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')  -- European Union is a subset of Europe
Group by location
order by TotalDeathCount desc


-- 3) Sort by country, order by highest percent population infected

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From dbo.CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc
-- If uploading table to excel for export in tableau, replace 'NULL's with 0.


-- 4.


Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From dbo.CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc
-- Warning, when you copy this table to excel, data field does not properly copy over. In excel, right click the data column,
-- click "format cells", go to custom, and enter 'yyyy-mm-dd hh:mm:ss.000' if you want original SQL datetime format,
-- or as far as Tableau is concerned, shortdate (m/dd/yyyy) works fine.













-- Queries I originally had, but excluded some because they were not used



-- 5) Total Vaccinations on a date by date report for individual locations, including their respective continents.

Select dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) as TotalVaccinatedByDate
--, (TotalVaccinatedByDate/population)*100
From dbo.CovidDeaths dea
Join dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.date, dea.population
order by 1,2,3


-- 6) CTE solution from Project 1 to presenting percentage of total vaccinations by certain date using aliases.

With PopsVacByDate (continent, location, date, population, new_vaccinations, TotalVaccinationsByDate)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as TotalVaccinationsByDate
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--and vac.new_vaccinations is not null
--order by 1,2,3
)
Select *,(TotalVaccinationsByDate/population) * 100 as VacByDatePercentage
from PopsVacByDate
order by 1,2,3
--order by VacByDatePercentage desc

