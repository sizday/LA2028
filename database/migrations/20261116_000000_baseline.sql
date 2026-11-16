-- liquibase formatted sql
-- changeset user:baseline

-- comment ============================================
-- comment LA2028 Sports Statistics Database Schema - Initial Baseline
-- comment ============================================

CREATE SCHEMA IF NOT EXISTS core;
ALTER SCHEMA core OWNER TO postgres;

-- comment ============================================
-- comment Reference Tables (Справочники)
-- comment ============================================

-- comment Таблица типов турниров (Tournaments_types)
CREATE TABLE IF NOT EXISTS core.tournaments_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL UNIQUE,
    importance_level INT NOT NULL DEFAULT 2
        CHECK (importance_level >= 0),
    description VARCHAR(1024)
);

-- comment Таблица регионов мира (Regions)
CREATE TABLE IF NOT EXISTS core.regions (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL UNIQUE,
    description VARCHAR(1024)
);

-- comment Связь региона и типов турниров (Regions_tournament_types)
CREATE TABLE IF NOT EXISTS core.region_tournaments_types (
    id BIGSERIAL PRIMARY KEY,
    region_id BIGINT NOT NULL,
    tournament_type_id BIGINT NOT NULL,
    FOREIGN KEY (region_id) REFERENCES core.regions(id) ON DELETE CASCADE,
    FOREIGN KEY (tournament_type_id) REFERENCES core.tournaments_types(id),
    CONSTRAINT region_tournaments_types_unique UNIQUE (region_id, tournament_type_id)
);

-- comment Таблица стран (Countries)
CREATE TABLE IF NOT EXISTS core.countries (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(256) NOT NULL UNIQUE,
    ioc_code VARCHAR(3) NOT NULL UNIQUE,
    region_id BIGINT,
    FOREIGN KEY (region_id) REFERENCES core.regions(id)
);

-- comment Таблица видов спорта (Sports)
CREATE TABLE IF NOT EXISTS core.sports (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL UNIQUE,
    description VARCHAR(1024)
);

-- comment Таблица дисциплин (Disciplines)
CREATE TABLE IF NOT EXISTS core.disciplines (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    sport_id BIGINT NOT NULL,
    description VARCHAR(1024),
    FOREIGN KEY (sport_id) REFERENCES core.sports(id),
    CONSTRAINT disciplines_sport_name_unique UNIQUE (sport_id, name)
);

-- comment Таблица спортсменов (Athletes)
CREATE TABLE IF NOT EXISTS core.athletes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    country_id BIGINT,
    sport_id BIGINT,
    birth_date DATE,
    wiki_link VARCHAR(2048),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (country_id) REFERENCES core.countries(id),
    FOREIGN KEY (sport_id) REFERENCES core.sports(id)
);

-- comment Связь спортсмена и дисциплин (Athletes_disciplines)
CREATE TABLE IF NOT EXISTS core.athlete_disciplines (
    id BIGSERIAL PRIMARY KEY,
    athlete_id BIGINT NOT NULL,
    discipline_id BIGINT NOT NULL,
    FOREIGN KEY (athlete_id) REFERENCES core.athletes(id) ON DELETE CASCADE,
    FOREIGN KEY (discipline_id) REFERENCES core.disciplines(id),
    CONSTRAINT athlete_disciplines_unique UNIQUE (athlete_id, discipline_id)
);

-- comment ============================================
-- comment Main Tables (Основные таблицы)
-- comment ============================================

-- comment Таблица турниров (Tournaments)
CREATE TABLE IF NOT EXISTS core.tournaments (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    sport_id BIGINT NOT NULL,
    tournament_type_id BIGINT NOT NULL,
    region_id BIGINT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sport_id) REFERENCES core.sports(id),
    FOREIGN KEY (tournament_type_id) REFERENCES core.tournaments_types(id),
    FOREIGN KEY (region_id) REFERENCES core.regions(id),
    CONSTRAINT tournaments_name_sport_unique UNIQUE (name, sport_id)
);

-- comment Таблица дисциплин-сессий конкретного турнира (Tournament_disciplines)
-- comment Один турнир (например "Волейбол, ОИ") разбивается на отдельные записи
-- comment по дисциплинам (мужчины/женщины), у каждого со своими датами проведения.
CREATE TABLE IF NOT EXISTS core.tournament_disciplines (
    id BIGSERIAL PRIMARY KEY,
    tournament_id BIGINT NOT NULL,
    discipline_id BIGINT NOT NULL,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tournament_id) REFERENCES core.tournaments(id) ON DELETE CASCADE,
    FOREIGN KEY (discipline_id) REFERENCES core.disciplines(id),
    CONSTRAINT tournament_disciplines_unique UNIQUE (tournament_id, discipline_id)
);

-- comment Таблица результатов (Results)
CREATE TABLE IF NOT EXISTS core.results (
    id BIGSERIAL PRIMARY KEY,
    tournament_discipline_id BIGINT NOT NULL,
    athlete_id BIGINT NOT NULL,
    place INT,
    score NUMERIC(18, 6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tournament_discipline_id) REFERENCES core.tournament_disciplines(id) ON DELETE CASCADE,
    FOREIGN KEY (athlete_id) REFERENCES core.athletes(id),
    CONSTRAINT results_tournament_discipline_athlete_unique UNIQUE (tournament_discipline_id, athlete_id)
);

-- comment ============================================
-- comment Reference Data (Справочные данные)
-- comment ============================================

-- comment Типы турниров
INSERT INTO core.tournaments_types (id, name, importance_level, description) VALUES (0, 'Olympic Games', 0, 'Олимпийские игры') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.tournaments_types (id, name, importance_level, description) VALUES (1, 'World Championship', 1, 'Чемпионат мира') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.tournaments_types (id, name, importance_level, description) VALUES (2, 'European Championship', 2, 'Чемпионат Европы') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.tournaments_types (id, name, importance_level, description) VALUES (3, 'American Championship', 2, 'Чемпионат Америки') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.tournaments_types (id, name, importance_level, description) VALUES (4, 'European Games', 2, 'Европейские игры') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.tournaments_types (id, name, importance_level, description) VALUES (5, 'Asian Games', 2, 'Азиатские игры') ON CONFLICT (id) DO NOTHING;

-- comment Регионы мира
INSERT INTO core.regions (id, name, description) VALUES (0, 'Europe', 'Европа') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.regions (id, name, description) VALUES (1, 'Africa', 'Африка') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.regions (id, name, description) VALUES (2, 'Asia', 'Азия') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.regions (id, name, description) VALUES (3, 'Oceania', 'Океания') ON CONFLICT (id) DO NOTHING;
INSERT INTO core.regions (id, name, description) VALUES (4, 'Pan America', 'Северная и Южная Америка') ON CONFLICT (id) DO NOTHING;

-- comment Связка регион -> типы турниров
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (0, 0, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (1, 0, 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (2, 0, 2) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (3, 0, 4) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (4, 4, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (5, 4, 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (6, 4, 3) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (7, 2, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (8, 2, 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (9, 2, 5) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (10, 1, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (11, 1, 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (12, 3, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO core.region_tournaments_types (id, region_id, tournament_type_id) VALUES (13, 3, 1) ON CONFLICT (id) DO NOTHING;

-- comment ============================================
-- comment Indexes for performance optimization
-- comment ============================================

CREATE INDEX IF NOT EXISTS idx_tournaments_types_importance ON core.tournaments_types(importance_level);

CREATE INDEX IF NOT EXISTS idx_region_tournaments_types_region_id ON core.region_tournaments_types(region_id);
CREATE INDEX IF NOT EXISTS idx_region_tournaments_types_tournament_type_id ON core.region_tournaments_types(tournament_type_id);

CREATE INDEX IF NOT EXISTS idx_countries_region_id ON core.countries(region_id);

CREATE INDEX IF NOT EXISTS idx_disciplines_sport_id ON core.disciplines(sport_id);

CREATE INDEX IF NOT EXISTS idx_athletes_country_id ON core.athletes(country_id);
CREATE INDEX IF NOT EXISTS idx_athletes_sport_id ON core.athletes(sport_id);
CREATE INDEX IF NOT EXISTS idx_athletes_birth_date ON core.athletes(birth_date);

CREATE INDEX IF NOT EXISTS idx_athlete_disciplines_athlete_id ON core.athlete_disciplines(athlete_id);
CREATE INDEX IF NOT EXISTS idx_athlete_disciplines_discipline_id ON core.athlete_disciplines(discipline_id);

CREATE INDEX IF NOT EXISTS idx_tournaments_sport_id ON core.tournaments(sport_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_tournament_type_id ON core.tournaments(tournament_type_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_region_id ON core.tournaments(region_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_start_date ON core.tournaments(start_date);

CREATE INDEX IF NOT EXISTS idx_tournament_disciplines_tournament_id ON core.tournament_disciplines(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_disciplines_discipline_id ON core.tournament_disciplines(discipline_id);

CREATE INDEX IF NOT EXISTS idx_results_tournament_discipline_id ON core.results(tournament_discipline_id);
CREATE INDEX IF NOT EXISTS idx_results_athlete_id ON core.results(athlete_id);
CREATE INDEX IF NOT EXISTS idx_results_place ON core.results(place);

-- comment ============================================
-- comment Comments on tables (Комментарии к таблицам)
-- comment ============================================

COMMENT ON TABLE core.tournaments_types IS 'Справочник типов турниров со степенью важности (0 - ОИ, 1 - ЧМ, 2 - континентальные)';
COMMENT ON TABLE core.regions IS 'Справочник регионов мира';
COMMENT ON TABLE core.region_tournaments_types IS 'Связь региона и типов турниров, проводимых в этом регионе';
COMMENT ON TABLE core.countries IS 'Справочник стран с IOC-кодами';
COMMENT ON TABLE core.sports IS 'Справочник видов спорта';
COMMENT ON TABLE core.disciplines IS 'Справочник дисциплин, привязанных к видам спорта';
COMMENT ON TABLE core.athletes IS 'Справочник спортсменов с привязкой к стране и виду спорта';
COMMENT ON TABLE core.athlete_disciplines IS 'Связь спортсмена и дисциплин, в которых он участвует';
COMMENT ON TABLE core.tournaments IS 'Турниры (вид спорта, тип, регион, общие даты проведения)';
COMMENT ON TABLE core.tournament_disciplines IS 'Дисциплины-сессии конкретного турнира с собственными датами проведения';
COMMENT ON TABLE core.results IS 'Результаты выступлений спортсменов в дисциплинах турнира';

-- changeset user:updated_at_trigger splitStatements:false
CREATE OR REPLACE FUNCTION core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- changeset user:updated_at_triggers

DROP TRIGGER IF EXISTS update_athletes_updated_at ON core.athletes;
CREATE TRIGGER update_athletes_updated_at BEFORE UPDATE ON core.athletes
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

DROP TRIGGER IF EXISTS update_tournaments_updated_at ON core.tournaments;
CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON core.tournaments
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

DROP TRIGGER IF EXISTS update_tournament_disciplines_updated_at ON core.tournament_disciplines;
CREATE TRIGGER update_tournament_disciplines_updated_at BEFORE UPDATE ON core.tournament_disciplines
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

DROP TRIGGER IF EXISTS update_results_updated_at ON core.results;
CREATE TRIGGER update_results_updated_at BEFORE UPDATE ON core.results
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

-- rollback
-- DROP SCHEMA IF EXISTS core CASCADE;
