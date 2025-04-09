-- Gegevensselecties
SELECT location, date, population, total_cases, new_cases, total_deaths, new_deaths, hosp_patients, icu_patients, reproduction_rate
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Nederland: Besmetting, Overlijden, Ziekenhuis en IC
SELECT location, date, population, total_cases, total_deaths,
       (total_cases / population) * 100 AS PercentPopulationInfected,
       (total_deaths / total_cases) * 100 AS PercentageInfectedDeath,
       (hosp_patients / total_cases) * 100 AS PercentCasesHospital,
       (icu_patients / total_cases) * 100 AS PercentCasesICU,
       CASE 
         WHEN DATEDIFF(DAY, '2020-02-27', date) < 10 THEN NULL
         ELSE CAST(hosp_patients AS INT) / total_cases * 100
       END AS CasePercentCasesHospital,
       CASE 
         WHEN DATEDIFF(DAY, '2020-02-27', date) < 10 THEN NULL
         ELSE CAST(icu_patients AS INT) / total_cases * 100
       END AS CasePercentCasesICU
FROM PortfolioProjectCovid..CovidDeaths
WHERE location = 'Netherlands' AND continent IS NOT NULL
ORDER BY 1, 2


-- Nederland: IC-capaciteit (wekelijkse opnames)
SELECT location, date, population, total_cases, weekly_icu_admissions,
       CASE 
         WHEN CAST(weekly_icu_admissions AS FLOAT) IS NULL THEN NULL
         WHEN CAST(weekly_icu_admissions AS FLOAT) > 175 THEN 'Overbelasting'
         ELSE 'Onder Controle'
       END AS Capaciteit
FROM PortfolioProjectCovid..CovidDeaths
WHERE location = 'Netherlands' AND continent IS NOT NULL
ORDER BY 1, 2


-- Nederland: Cumulatief aantal besmettingen
SELECT date, location, total_cases, new_cases,
       SUM(new_cases) OVER (ORDER BY date) AS RunningTotal,
       AVG(new_cases) OVER (ORDER BY date) AS RunningAVG,
       COUNT(new_cases) OVER (ORDER BY date) AS RunningCount,
       SUM(new_cases) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS Rolling7DaySum,
       AVG(new_cases) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS Rolling7DayAvg
FROM PortfolioProjectCovid..CovidDeaths
WHERE location = 'Netherlands' AND continent IS NOT NULL


-- Nederland: Verandering in besmettingen per dag
SELECT date, location, total_cases, new_cases,
       LAG(new_cases, 1, 0) OVER (ORDER BY date) AS CasesGisteren,
       LEAD(new_cases, 1, 0) OVER (ORDER BY date) AS CasesMorgen,
       new_cases - LAG(new_cases, 1, 0) OVER (ORDER BY date) AS CasesVerandering,
       new_cases * 100.0 / NULLIF(LAG(new_cases, 1, 0) OVER (ORDER BY date), 0) AS '%Toename'
FROM PortfolioProjectCovid..CovidDeaths
WHERE location = 'Netherlands' AND continent IS NOT NULL


-- Nederland: Dag met meeste besmettingen (buckets)
SELECT date, location, new_cases,
       ROW_NUMBER() OVER (ORDER BY new_cases DESC) AS RowNumber,
       NTILE(5) OVER (ORDER BY new_cases DESC) AS BucketTop5
FROM PortfolioProjectCovid..CovidDeaths
WHERE location = 'Netherlands' AND continent IS NOT NULL


-- Infectiepercentage per continent
SELECT continent,
       SUM(population) AS ContinentPopulation,
       SUM(new_cases) AS TotalInfected,
       SUM(new_cases) / SUM(population) * 100 AS PercentPopulationInfected
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY PercentPopulationInfected DESC


-- Infectiepercentage per land + impactclassificatie
SELECT location, population,
       MAX(total_cases) AS HighestInfectionCount,
       MAX((total_cases) / population) * 100 AS PercentPopulationInfected,
       CASE 
         WHEN MAX(total_cases) IS NULL OR population IS NULL THEN NULL
         WHEN MAX((total_cases) / population) * 100 > 10 THEN 'High Impact'
         WHEN MAX((total_cases) / population) * 100 > 5 THEN 'Medium Impact'
         ELSE 'Low Impact'
       END AS Impact
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


-- Overlijdenspercentage per continent
SELECT continent,
       MAX(total_deaths) AS TotalDeathCount,
       MAX((total_deaths) / population) * 100 AS PercentPopulationDeath
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 3 DESC


-- Overlijdenspercentage per land
SELECT location, population,
       MAX(total_deaths) AS TotalDeathCount,
       MAX((total_deaths) / population) * 100 AS PercentPopulationDeath
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


-- Ranglijst overlijdenspercentage per continent
SELECT continent, location, population,
       MAX(total_cases) AS TotalCases,
       MAX(total_deaths) AS TotalDeaths,
       MAX(CAST(total_deaths AS FLOAT)) * 100.0 / MAX(CAST(total_cases AS FLOAT)) AS DeathPercentage,
       RANK() OVER (PARTITION BY continent ORDER BY MAX(CAST(total_deaths AS FLOAT)) / MAX(CAST(total_cases AS FLOAT)) DESC) AS DeathRank
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
HAVING MAX(total_cases) > 0


-- Ziekenhuisdruk per continent
SELECT continent,
       SUM(population) AS ContinentPopulation,
       SUM(CAST(hosp_patients AS INT)) AS TotalHospitalPatients,
       SUM(CAST(hosp_patients AS INT)) * 100.0 / SUM(population) AS PercentPopulationHospital
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY PercentPopulationHospital DESC


-- Ziekenhuisdruk per land
SELECT location, population,
       SUM(CAST(hosp_patients AS INT)) AS TotalHospitalPatients,
       SUM(CAST(hosp_patients AS INT)) * 100.0 / population AS PercentPopulationHospital
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


-- IC-druk per continent
SELECT continent,
       SUM(population) AS ContinentPopulation,
       SUM(CAST(icu_patients AS INT)) AS TotalICUPatients,
       SUM(CAST(icu_patients AS INT)) * 100.0 / SUM(population) AS PercentPopulationICU
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY PercentPopulationICU DESC


-- IC-druk per land
SELECT location, population,
       SUM(CAST(icu_patients AS INT)) AS TotalICUPatients,
       SUM(CAST(icu_patients AS INT)) * 100.0 / population AS PercentPopulationICU
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationICU DESC


-- Wereldwijde overlijdensstatistieken per dag
SELECT date,
       SUM(new_cases) AS total_cases,
       MAX(CAST(total_deaths AS INT)) AS total_deaths,
       MAX(CAST(total_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2


-- Cumulatief aantal gevaccineerde mensen (CTE)
WITH PopvsVac AS (
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
         SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
  FROM PortfolioProjectCovid..CovidDeaths dea
  JOIN PortfolioProjectCovid..CovidVaccinations vac
       ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentagePopulationVaccinated
FROM PopvsVac


-- View aanmaken om vaccinatiegegevens op te slaan
DROP VIEW IF EXISTS PercentPopulationVaccinated;

CREATE VIEW PercentPopulationVaccinated AS
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
         SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
  FROM PortfolioProjectCovid..CovidDeaths dea
  JOIN PortfolioProjectCovid..CovidVaccinations vac
       ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL