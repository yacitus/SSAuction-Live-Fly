--
-- PostgreSQL database dump
--

\restrict gOUraplXyCOeZKaA346hf6vcuiDfv8XslIhWI1KWJwASbqIS3gIU3WSQxHIwaih

-- Dumped from database version 17.9 (Postgres.app)
-- Dumped by pg_dump version 17.9 (Postgres.app)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: all_players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.all_players (
    id bigint NOT NULL,
    year_range character varying(255) NOT NULL,
    ssnum integer NOT NULL,
    name character varying(255) NOT NULL,
    "position" character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL
);


--
-- Name: all_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.all_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: all_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.all_players_id_seq OWNED BY public.all_players.id;


--
-- Name: auctions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auctions (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    year_range character varying(255) NOT NULL,
    nominations_per_team integer NOT NULL,
    seconds_before_autonomination integer NOT NULL,
    new_nominations_created character varying(255) NOT NULL,
    bid_timeout_seconds integer NOT NULL,
    active boolean NOT NULL,
    players_per_team integer NOT NULL,
    must_roster_all_players boolean NOT NULL,
    dollars_per_team integer NOT NULL,
    started_or_paused_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    initial_bid_timeout_seconds integer DEFAULT 86400,
    allow_player_cuts boolean DEFAULT false,
    unlimited_nominations boolean DEFAULT false
);


--
-- Name: auctions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auctions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auctions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auctions_id_seq OWNED BY public.auctions.id;


--
-- Name: auctions_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auctions_users (
    id bigint NOT NULL,
    auction_id bigint,
    user_id bigint
);


--
-- Name: auctions_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auctions_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auctions_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auctions_users_id_seq OWNED BY public.auctions_users.id;


--
-- Name: bid_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bid_logs (
    id bigint NOT NULL,
    amount integer NOT NULL,
    type character varying(255) NOT NULL,
    datetime timestamp(0) without time zone NOT NULL,
    auction_id bigint,
    team_id bigint,
    player_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: bid_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bid_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bid_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bid_logs_id_seq OWNED BY public.bid_logs.id;


--
-- Name: bids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bids (
    id bigint NOT NULL,
    bid_amount integer NOT NULL,
    hidden_high_bid integer,
    expires_at timestamp(0) without time zone NOT NULL,
    nominated_by integer NOT NULL,
    team_id bigint,
    auction_id bigint,
    closed boolean NOT NULL,
    inserted_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL
);


--
-- Name: bids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bids_id_seq OWNED BY public.bids.id;


--
-- Name: cut_players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cut_players (
    id bigint NOT NULL,
    cost integer NOT NULL,
    team_id bigint NOT NULL,
    auction_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: cut_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cut_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cut_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cut_players_id_seq OWNED BY public.cut_players.id;


--
-- Name: ordered_players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordered_players (
    id bigint NOT NULL,
    rank integer NOT NULL,
    player_id bigint,
    team_id bigint,
    auction_id bigint,
    inserted_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL
);


--
-- Name: ordered_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordered_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordered_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordered_players_id_seq OWNED BY public.ordered_players.id;


--
-- Name: player_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_values (
    id bigint NOT NULL,
    value integer,
    player_id bigint NOT NULL,
    team_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: player_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.player_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.player_values_id_seq OWNED BY public.player_values.id;


--
-- Name: players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.players (
    id bigint NOT NULL,
    year_range character varying(255) NOT NULL,
    ssnum integer NOT NULL,
    name character varying(255) NOT NULL,
    "position" character varying(255) NOT NULL,
    bid_id bigint,
    rostered_player_id bigint,
    auction_id bigint,
    inserted_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL,
    cut_player_id bigint
);


--
-- Name: players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.players_id_seq OWNED BY public.players.id;


--
-- Name: rostered_players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rostered_players (
    id bigint NOT NULL,
    cost integer NOT NULL,
    team_id bigint,
    auction_id bigint,
    inserted_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL
);


--
-- Name: rostered_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rostered_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rostered_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rostered_players_id_seq OWNED BY public.rostered_players.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    unused_nominations integer NOT NULL,
    time_nominations_expire timestamp(0) without time zone,
    new_nominations_open_at timestamp(0) without time zone,
    auction_id bigint,
    inserted_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT '2021-01-01 00:00:01'::timestamp without time zone NOT NULL,
    total_supplemental_dollars integer DEFAULT 0,
    ssnum integer
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: teams_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams_users (
    id bigint NOT NULL,
    team_id bigint,
    user_id bigint
);


--
-- Name: teams_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_users_id_seq OWNED BY public.teams_users.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    username character varying(255) NOT NULL,
    email public.citext NOT NULL,
    super boolean NOT NULL,
    hashed_password character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    slack_display_name character varying(255) NOT NULL,
    confirmed_at timestamp(0) without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_tokens_id_seq OWNED BY public.users_tokens.id;


--
-- Name: all_players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.all_players ALTER COLUMN id SET DEFAULT nextval('public.all_players_id_seq'::regclass);


--
-- Name: auctions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auctions ALTER COLUMN id SET DEFAULT nextval('public.auctions_id_seq'::regclass);


--
-- Name: auctions_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auctions_users ALTER COLUMN id SET DEFAULT nextval('public.auctions_users_id_seq'::regclass);


--
-- Name: bid_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bid_logs ALTER COLUMN id SET DEFAULT nextval('public.bid_logs_id_seq'::regclass);


--
-- Name: bids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids ALTER COLUMN id SET DEFAULT nextval('public.bids_id_seq'::regclass);


--
-- Name: cut_players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cut_players ALTER COLUMN id SET DEFAULT nextval('public.cut_players_id_seq'::regclass);


--
-- Name: ordered_players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordered_players ALTER COLUMN id SET DEFAULT nextval('public.ordered_players_id_seq'::regclass);


--
-- Name: player_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_values ALTER COLUMN id SET DEFAULT nextval('public.player_values_id_seq'::regclass);


--
-- Name: players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players ALTER COLUMN id SET DEFAULT nextval('public.players_id_seq'::regclass);


--
-- Name: rostered_players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rostered_players ALTER COLUMN id SET DEFAULT nextval('public.rostered_players_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: teams_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users ALTER COLUMN id SET DEFAULT nextval('public.teams_users_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: users_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens ALTER COLUMN id SET DEFAULT nextval('public.users_tokens_id_seq'::regclass);


--
-- Name: all_players all_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.all_players
    ADD CONSTRAINT all_players_pkey PRIMARY KEY (id);


--
-- Name: auctions auctions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auctions
    ADD CONSTRAINT auctions_pkey PRIMARY KEY (id);


--
-- Name: auctions_users auctions_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auctions_users
    ADD CONSTRAINT auctions_users_pkey PRIMARY KEY (id);


--
-- Name: bid_logs bid_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bid_logs
    ADD CONSTRAINT bid_logs_pkey PRIMARY KEY (id);


--
-- Name: bids bids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_pkey PRIMARY KEY (id);


--
-- Name: cut_players cut_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cut_players
    ADD CONSTRAINT cut_players_pkey PRIMARY KEY (id);


--
-- Name: ordered_players ordered_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordered_players
    ADD CONSTRAINT ordered_players_pkey PRIMARY KEY (id);


--
-- Name: player_values player_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_values
    ADD CONSTRAINT player_values_pkey PRIMARY KEY (id);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: rostered_players rostered_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rostered_players
    ADD CONSTRAINT rostered_players_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: teams_users teams_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users
    ADD CONSTRAINT teams_users_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_tokens users_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_pkey PRIMARY KEY (id);


--
-- Name: all_players_year_range_ssnum_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX all_players_year_range_ssnum_index ON public.all_players USING btree (year_range, ssnum);


--
-- Name: auctions_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX auctions_name_index ON public.auctions USING btree (name);


--
-- Name: auctions_users_auction_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX auctions_users_auction_id_user_id_index ON public.auctions_users USING btree (auction_id, user_id);


--
-- Name: player_values_player_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX player_values_player_id_index ON public.player_values USING btree (player_id);


--
-- Name: player_values_team_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX player_values_team_id_index ON public.player_values USING btree (team_id);


--
-- Name: teams_users_team_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX teams_users_team_id_user_id_index ON public.teams_users USING btree (team_id, user_id);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_tokens_context_token_index ON public.users_tokens USING btree (context, token);


--
-- Name: users_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_tokens_user_id_index ON public.users_tokens USING btree (user_id);


--
-- Name: users_username_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_username_email_index ON public.users USING btree (username, email);


--
-- Name: users_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_username_index ON public.users USING btree (username);


--
-- Name: auctions_users auctions_users_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auctions_users
    ADD CONSTRAINT auctions_users_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES public.auctions(id);


--
-- Name: auctions_users auctions_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auctions_users
    ADD CONSTRAINT auctions_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: bid_logs bid_logs_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bid_logs
    ADD CONSTRAINT bid_logs_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES public.auctions(id);


--
-- Name: bid_logs bid_logs_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bid_logs
    ADD CONSTRAINT bid_logs_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: bid_logs bid_logs_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bid_logs
    ADD CONSTRAINT bid_logs_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: bids bids_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES public.auctions(id);


--
-- Name: bids bids_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: cut_players cut_players_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cut_players
    ADD CONSTRAINT cut_players_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES public.auctions(id);


--
-- Name: cut_players cut_players_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cut_players
    ADD CONSTRAINT cut_players_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: ordered_players ordered_players_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordered_players
    ADD CONSTRAINT ordered_players_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES public.auctions(id);


--
-- Name: ordered_players ordered_players_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordered_players
    ADD CONSTRAINT ordered_players_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: ordered_players ordered_players_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordered_players
    ADD CONSTRAINT ordered_players_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: player_values player_values_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_values
    ADD CONSTRAINT player_values_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: player_values player_values_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_values
    ADD CONSTRAINT player_values_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: players players_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES public.auctions(id);


--
-- Name: players players_bid_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_bid_id_fkey FOREIGN KEY (bid_id) REFERENCES public.bids(id);


--
-- Name: players players_cut_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_cut_player_id_fkey FOREIGN KEY (cut_player_id) REFERENCES public.cut_players(id);


--
-- Name: players players_rostered_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_rostered_player_id_fkey FOREIGN KEY (rostered_player_id) REFERENCES public.rostered_players(id);


--
-- Name: rostered_players rostered_players_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rostered_players
    ADD CONSTRAINT rostered_players_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES public.auctions(id);


--
-- Name: rostered_players rostered_players_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rostered_players
    ADD CONSTRAINT rostered_players_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: teams teams_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES public.auctions(id);


--
-- Name: teams_users teams_users_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users
    ADD CONSTRAINT teams_users_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: teams_users teams_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users
    ADD CONSTRAINT teams_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users_tokens users_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict gOUraplXyCOeZKaA346hf6vcuiDfv8XslIhWI1KWJwASbqIS3gIU3WSQxHIwaih

INSERT INTO public."schema_migrations" (version) VALUES (20190901163909);
INSERT INTO public."schema_migrations" (version) VALUES (20190901174613);
INSERT INTO public."schema_migrations" (version) VALUES (20190901180401);
INSERT INTO public."schema_migrations" (version) VALUES (20190901202304);
INSERT INTO public."schema_migrations" (version) VALUES (20190901202719);
INSERT INTO public."schema_migrations" (version) VALUES (20190902030142);
INSERT INTO public."schema_migrations" (version) VALUES (20190907181155);
INSERT INTO public."schema_migrations" (version) VALUES (20190907181349);
INSERT INTO public."schema_migrations" (version) VALUES (20190922183400);
INSERT INTO public."schema_migrations" (version) VALUES (20191006200151);
INSERT INTO public."schema_migrations" (version) VALUES (20191013044545);
INSERT INTO public."schema_migrations" (version) VALUES (20191013050920);
INSERT INTO public."schema_migrations" (version) VALUES (20191111172509);
INSERT INTO public."schema_migrations" (version) VALUES (20200518024714);
INSERT INTO public."schema_migrations" (version) VALUES (20210102220119);
INSERT INTO public."schema_migrations" (version) VALUES (20210103054210);
INSERT INTO public."schema_migrations" (version) VALUES (20210103054451);
INSERT INTO public."schema_migrations" (version) VALUES (20210103054612);
INSERT INTO public."schema_migrations" (version) VALUES (20210103054727);
INSERT INTO public."schema_migrations" (version) VALUES (20210103054849);
INSERT INTO public."schema_migrations" (version) VALUES (20210103215400);
INSERT INTO public."schema_migrations" (version) VALUES (20210221023306);
INSERT INTO public."schema_migrations" (version) VALUES (20220116224034);
INSERT INTO public."schema_migrations" (version) VALUES (20220116224441);
INSERT INTO public."schema_migrations" (version) VALUES (20220117203822);
INSERT INTO public."schema_migrations" (version) VALUES (20220117204008);
INSERT INTO public."schema_migrations" (version) VALUES (20220218003221);
INSERT INTO public."schema_migrations" (version) VALUES (20220425170551);
INSERT INTO public."schema_migrations" (version) VALUES (20220426024314);
INSERT INTO public."schema_migrations" (version) VALUES (20220428163423);
INSERT INTO public."schema_migrations" (version) VALUES (20221018014827);
INSERT INTO public."schema_migrations" (version) VALUES (20221023212033);
INSERT INTO public."schema_migrations" (version) VALUES (20221031030956);
INSERT INTO public."schema_migrations" (version) VALUES (20221126203653);
INSERT INTO public."schema_migrations" (version) VALUES (20260413000000);
