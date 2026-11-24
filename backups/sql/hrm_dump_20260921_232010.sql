--
-- PostgreSQL database dump
--

\restrict pGmcjJPPX2YW85Hxf7iQn8aYce7yJTiMKllHiXZtsnIyzT6Li2J2EV71OOSH5XF

-- Dumped from database version 17.11 (Debian 17.11-1.pgdg12+2)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg12+2)

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: attendances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendances (
    attendance_id uuid NOT NULL,
    clock_in_time time(0) without time zone,
    clock_out_time time(0) without time zone,
    status character varying(255) NOT NULL,
    work_date date NOT NULL,
    shift_id uuid NOT NULL,
    user_id uuid NOT NULL,
    is_edited boolean DEFAULT false NOT NULL,
    edited_by uuid,
    edited_reason character varying(255),
    is_deleted boolean DEFAULT false NOT NULL,
    CONSTRAINT attendances_status_check CHECK (((status)::text = ANY (ARRAY[('NOT_CHECKED'::character varying)::text, ('WORKING'::character varying)::text, ('SUFFICIENT'::character varying)::text, ('LATE'::character varying)::text, ('EARLY'::character varying)::text, ('LATE_AND_EARLY'::character varying)::text, ('MISSING'::character varying)::text, ('UNEXCUSED_ABSENCE'::character varying)::text, ('PAID_LEAVE'::character varying)::text, ('UNPAID_LEAVE'::character varying)::text, ('HOLIDAY'::character varying)::text, ('BUSINESS_TRIP'::character varying)::text, ('ADJUSTED'::character varying)::text])))
);


ALTER TABLE public.attendances OWNER TO postgres;

--
-- Name: comment_reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comment_reactions (
    reaction_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    reaction character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    comment_id uuid NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT comment_reactions_reaction_check CHECK (((reaction)::text = ANY (ARRAY[('Like'::character varying)::text, ('Love'::character varying)::text, ('Dislike'::character varying)::text, ('Angry'::character varying)::text, ('Sad'::character varying)::text])))
);


ALTER TABLE public.comment_reactions OWNER TO postgres;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments (
    comment_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    media_url character varying(255),
    reaction_count integer NOT NULL,
    reply_count integer NOT NULL,
    text_content character varying(255),
    updated_at timestamp(6) without time zone NOT NULL,
    parent_comment_id uuid,
    interactable_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.comments OWNER TO postgres;

--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    department_id uuid NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: employee_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_number_seq OWNER TO postgres;

--
-- Name: hashtags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hashtags (
    hashtag_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    hashtag_name character varying(255) NOT NULL
);


ALTER TABLE public.hashtags OWNER TO postgres;

--
-- Name: holidays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.holidays (
    holiday_id uuid NOT NULL,
    date date NOT NULL,
    description character varying(255) NOT NULL
);


ALTER TABLE public.holidays OWNER TO postgres;

--
-- Name: interactables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.interactables (
    id uuid NOT NULL,
    type character varying(255) NOT NULL,
    CONSTRAINT interactables_type_check CHECK (((type)::text = ANY (ARRAY[('post'::character varying)::text, ('share'::character varying)::text])))
);


ALTER TABLE public.interactables OWNER TO postgres;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    job_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    department_id uuid NOT NULL
);


ALTER TABLE public.jobs OWNER TO postgres;

--
-- Name: leave_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.leave_requests (
    request_id uuid NOT NULL,
    from_date date NOT NULL,
    reason character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    approver_id uuid,
    requestor_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    to_date date NOT NULL,
    paid_leave_days integer DEFAULT 0 NOT NULL,
    rejection_reason character varying(255),
    CONSTRAINT chk_leave_dates CHECK ((from_date <= to_date)),
    CONSTRAINT chk_paid_leave_days CHECK ((paid_leave_days >= 0)),
    CONSTRAINT leave_requests_status_check CHECK (((status)::text = ANY (ARRAY[('accepted'::character varying)::text, ('rejected'::character varying)::text, ('pending'::character varying)::text])))
);


ALTER TABLE public.leave_requests OWNER TO postgres;

--
-- Name: monthly_payroll_summaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.monthly_payroll_summaries (
    summary_id uuid DEFAULT gen_random_uuid() NOT NULL,
    period_month integer NOT NULL,
    period_year integer NOT NULL,
    total_employees integer NOT NULL,
    total_gross_pay numeric(18,2) DEFAULT 0 NOT NULL,
    total_net_pay numeric(18,2) DEFAULT 0 NOT NULL,
    total_basic_pay numeric(18,2) DEFAULT 0 NOT NULL,
    total_overtime_pay numeric(18,2) DEFAULT 0 NOT NULL,
    total_bonus_pay numeric(18,2) DEFAULT 0 NOT NULL,
    total_allowance_pay numeric(18,2) DEFAULT 0 NOT NULL,
    total_personal_income_tax numeric(18,2) DEFAULT 0 NOT NULL,
    total_employee_insurance numeric(18,2) DEFAULT 0 NOT NULL,
    total_company_insurance numeric(18,2) DEFAULT 0 NOT NULL,
    total_union_fee numeric(18,2) DEFAULT 0 NOT NULL,
    total_company_cost numeric(18,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(6) without time zone,
    CONSTRAINT monthly_payroll_summaries_period_month_check CHECK (((period_month >= 1) AND (period_month <= 12))),
    CONSTRAINT monthly_payroll_summaries_period_year_check CHECK ((period_year >= 2020))
);


ALTER TABLE public.monthly_payroll_summaries OWNER TO postgres;

--
-- Name: monthly_timesheets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.monthly_timesheets (
    timesheet_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    period_month integer NOT NULL,
    period_year integer NOT NULL,
    standard_working_days integer DEFAULT 26 NOT NULL,
    actual_worked_days numeric(4,2) DEFAULT 0 NOT NULL,
    actual_work_hours numeric(6,2) DEFAULT 0 NOT NULL,
    late_count integer DEFAULT 0 NOT NULL,
    total_late_minutes integer DEFAULT 0 NOT NULL,
    early_departure_count integer DEFAULT 0 NOT NULL,
    absent_days numeric(4,2) DEFAULT 0 NOT NULL,
    paid_leave_days numeric(4,2) DEFAULT 0 NOT NULL,
    unpaid_leave_days numeric(4,2) DEFAULT 0 NOT NULL,
    total_actual_ot_hours numeric(6,2) DEFAULT 0 NOT NULL,
    total_paid_ot_hours numeric(6,2) DEFAULT 0 NOT NULL,
    ot_details jsonb,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    note character varying(255),
    locked_at timestamp with time zone,
    locked_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT monthly_timesheets_period_month_check CHECK (((period_month >= 1) AND (period_month <= 12))),
    CONSTRAINT monthly_timesheets_period_year_check CHECK ((period_year >= 2020))
);


ALTER TABLE public.monthly_timesheets OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    notification_id uuid NOT NULL,
    count integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    entity_id uuid NOT NULL,
    entity_type character varying(255) NOT NULL,
    is_read boolean NOT NULL,
    is_seen boolean NOT NULL,
    type character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    recipent_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    CONSTRAINT notifications_entity_type_check CHECK (((entity_type)::text = ANY (ARRAY[('POST'::character varying)::text, ('COMMENT'::character varying)::text, ('USer'::character varying)::text]))),
    CONSTRAINT notifications_type_check CHECK (((type)::text = ANY (ARRAY[('POST_REACTION'::character varying)::text, ('COMMENT'::character varying)::text, ('REPLY'::character varying)::text, ('COMMENT_REACTION'::character varying)::text, ('SHARE'::character varying)::text, ('FRIEND_REQUEST'::character varying)::text, ('ACCEPT_FRIEND_REQUEST'::character varying)::text])))
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: overtime_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.overtime_records (
    overtime_record_id uuid NOT NULL,
    approved_date date NOT NULL,
    approved_end_time timestamp(6) without time zone NOT NULL,
    approved_start_time timestamp(6) without time zone NOT NULL,
    clock_in_time timestamp(6) without time zone,
    clock_out_time timestamp(6) without time zone,
    is_holiday boolean NOT NULL,
    is_night_time boolean NOT NULL,
    is_weekend boolean NOT NULL,
    status character varying(255) NOT NULL,
    approver_id uuid,
    requestor_id uuid NOT NULL,
    reason character varying(255),
    rejection_reason character varying(255),
    CONSTRAINT overtime_records_status_check CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('accepted'::character varying)::text, ('rejected'::character varying)::text])))
);


ALTER TABLE public.overtime_records OWNER TO postgres;

--
-- Name: payrolls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payrolls (
    payroll_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    timesheet_id uuid NOT NULL,
    period_month integer NOT NULL,
    period_year integer NOT NULL,
    base_salary numeric(15,2) NOT NULL,
    hourly_rate numeric(15,2) NOT NULL,
    basic_pay numeric(15,2) DEFAULT 0 NOT NULL,
    overtime_pay numeric(15,2) DEFAULT 0 NOT NULL,
    allowance_pay numeric(15,2) DEFAULT 0 NOT NULL,
    bonus_pay numeric(15,2) DEFAULT 0 NOT NULL,
    gross_pay numeric(15,2) DEFAULT 0 NOT NULL,
    insurance_deduction numeric(15,2) DEFAULT 0 NOT NULL,
    tax_deduction numeric(15,2) DEFAULT 0 NOT NULL,
    other_deduction numeric(15,2) DEFAULT 0 NOT NULL,
    total_deduction numeric(15,2) DEFAULT 0 NOT NULL,
    net_pay numeric(15,2) NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    note character varying(255),
    calculated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    approved_at timestamp with time zone,
    paid_at timestamp with time zone,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    CONSTRAINT payrolls_period_month_check CHECK (((period_month >= 1) AND (period_month <= 12))),
    CONSTRAINT payrolls_period_year_check CHECK ((period_year >= 2020))
);


ALTER TABLE public.payrolls OWNER TO postgres;

--
-- Name: pending_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pending_users (
    id uuid NOT NULL,
    birth_date date NOT NULL,
    code integer NOT NULL,
    created_date timestamp(6) without time zone NOT NULL,
    email character varying(255) NOT NULL,
    first_name character varying(255) NOT NULL,
    gender character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    pending_id uuid NOT NULL,
    base_salary numeric(38,2),
    citizen_id character varying(255),
    contract_end_date date,
    contract_start_date date,
    contract_type character varying(255),
    created_at timestamp(6) with time zone NOT NULL,
    personal_email character varying(255) NOT NULL,
    phone_number character varying(255),
    place_of_birth character varying(255),
    rejection_reason character varying(255),
    status character varying(255) NOT NULL,
    updated_at timestamp(6) with time zone,
    created_by uuid,
    department_id uuid NOT NULL,
    job_id uuid NOT NULL,
    shift_id uuid
);


ALTER TABLE public.pending_users OWNER TO postgres;

--
-- Name: post_hashtag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_hashtag (
    post_id uuid NOT NULL,
    hashtag_id uuid NOT NULL
);


ALTER TABLE public.post_hashtag OWNER TO postgres;

--
-- Name: post_reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_reactions (
    reaction_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    reaction character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    interactable_id uuid NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT post_reactions_reaction_check CHECK (((reaction)::text = ANY (ARRAY[('Like'::character varying)::text, ('Love'::character varying)::text, ('Dislike'::character varying)::text, ('Angry'::character varying)::text, ('Sad'::character varying)::text])))
);


ALTER TABLE public.post_reactions OWNER TO postgres;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posts (
    post_id uuid NOT NULL,
    comment_count integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    media_urls jsonb,
    reaction_count integer NOT NULL,
    share_count integer NOT NULL,
    text character varying(255),
    updatedd_at timestamp(6) without time zone NOT NULL,
    visibility character varying(255) NOT NULL,
    interactable_id uuid,
    user_id uuid NOT NULL,
    CONSTRAINT posts_visibility_check CHECK (((visibility)::text = ANY (ARRAY[('PUBLIC'::character varying)::text, ('FRIENDS'::character varying)::text, ('PRIVATE'::character varying)::text])))
);


ALTER TABLE public.posts OWNER TO postgres;

--
-- Name: resignation_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resignation_requests (
    resignation_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    hr_approved_at timestamp(6) without time zone,
    hr_comment character varying(255),
    last_working_date date NOT NULL,
    manager_approved_at timestamp(6) without time zone,
    manager_comment character varying(255),
    reason character varying(500) NOT NULL,
    status character varying(30) NOT NULL,
    submitted_time timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone,
    hr_or_executive_id uuid,
    manager_id uuid,
    user_id uuid NOT NULL,
    CONSTRAINT resignation_requests_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('MANAGER_APPROVED'::character varying)::text, ('MANAGER_REJECTED'::character varying)::text, ('APPROVED'::character varying)::text, ('REJECTED'::character varying)::text, ('CANCELLED'::character varying)::text, ('COMPLETED'::character varying)::text])))
);


ALTER TABLE public.resignation_requests OWNER TO postgres;

--
-- Name: salaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salaries (
    salary_id uuid NOT NULL,
    base_salary double precision NOT NULL,
    end_date date,
    is_active boolean NOT NULL,
    pay_frequency character varying(255) NOT NULL,
    start_date date NOT NULL,
    work_days double precision NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT salaries_pay_frequency_check CHECK (((pay_frequency)::text = ANY (ARRAY[('HOURLY'::character varying)::text, ('WEEKLY'::character varying)::text, ('MONTHLY'::character varying)::text])))
);


ALTER TABLE public.salaries OWNER TO postgres;

--
-- Name: shares; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shares (
    share_id uuid NOT NULL,
    comment_count integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    reaction_count integer NOT NULL,
    text_content character varying(255),
    visibility character varying(255) NOT NULL,
    interactable_id uuid,
    post_id uuid NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT shares_visibility_check CHECK (((visibility)::text = ANY (ARRAY[('PUBLIC'::character varying)::text, ('FRIENDS'::character varying)::text, ('PRIVATE'::character varying)::text])))
);


ALTER TABLE public.shares OWNER TO postgres;

--
-- Name: user_bank_accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_bank_accounts (
    user_id uuid NOT NULL,
    bank_account_number character varying(255),
    bank_name character varying(255)
);


ALTER TABLE public.user_bank_accounts OWNER TO postgres;

--
-- Name: user_contracts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_contracts (
    user_id uuid NOT NULL,
    contract_end_date date,
    contract_start_date date,
    contract_type character varying(255),
    contract_id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public.user_contracts OWNER TO postgres;

--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_profiles (
    user_id uuid NOT NULL,
    citizen_id_number character varying(255),
    emergency_contact_name character varying(255),
    emergency_contact_phone character varying(255),
    marital_status character varying(255),
    nationality character varying(255),
    personal_email character varying(255),
    phone_number character varying(255),
    place_of_birth character varying(255),
    social_insurance_number character varying(255),
    social_insurance_start_date date,
    tax_identification_number character varying(255)
);


ALTER TABLE public.user_profiles OWNER TO postgres;

--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_sessions (
    session_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    device_id uuid NOT NULL,
    meta_data jsonb NOT NULL,
    revoked boolean DEFAULT false NOT NULL,
    token text NOT NULL,
    user_id uuid NOT NULL,
    last_active_at timestamp(6) without time zone
);


ALTER TABLE public.user_sessions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id uuid NOT NULL,
    annual_leave_days integer NOT NULL,
    birth_date date NOT NULL,
    email character varying(255) NOT NULL,
    first_name character varying(255) NOT NULL,
    gender character varying(255) NOT NULL,
    joined_date date NOT NULL,
    last_name character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    profile_pic_url character varying(255) NOT NULL,
    used_leave_days integer NOT NULL,
    department_id uuid NOT NULL,
    job_id uuid NOT NULL,
    face_embedding public.vector(128),
    employee_code character varying(10) NOT NULL,
    shift_id uuid NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: work_shift_schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.work_shift_schedules (
    schedule_id uuid NOT NULL,
    day_of_week integer NOT NULL,
    end_time time(0) without time zone NOT NULL,
    is_working boolean NOT NULL,
    rest_end_time time(0) without time zone,
    rest_start_time time(0) without time zone,
    start_time time(0) without time zone NOT NULL,
    shift_id uuid NOT NULL
);


ALTER TABLE public.work_shift_schedules OWNER TO postgres;

--
-- Name: work_shifts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.work_shifts (
    shift_id uuid NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.work_shifts OWNER TO postgres;

--
-- Data for Name: attendances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendances (attendance_id, clock_in_time, clock_out_time, status, work_date, shift_id, user_id, is_edited, edited_by, edited_reason, is_deleted) FROM stdin;
a9fea941-a089-1454-81a0-89249f0e0105	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f0106	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f0107	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f0108	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f0109	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f010a	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f010b	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f010c	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f010d	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f010e	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f010f	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f0f0110	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100111	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100112	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100113	\N	\N	HOLIDAY	2026-01-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100114	07:55:00	17:22:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100115	07:54:00	17:21:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100116	07:56:00	17:23:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100117	07:57:00	17:24:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100118	07:50:00	17:17:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100119	07:48:00	17:15:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f10011a	07:55:00	17:12:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f10011b	08:17:00	17:12:00	LATE	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f10011c	07:52:00	16:39:00	EARLY	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f10011d	07:56:00	17:23:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f10011e	07:50:00	17:07:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f10011f	07:50:00	17:17:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100120	07:49:00	17:06:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100121	07:50:00	\N	MISSING	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100122	07:48:00	17:05:00	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100123	07:48:00	17:05:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100124	07:57:00	17:24:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100125	07:49:00	17:06:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100126	07:50:00	17:07:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100127	07:57:00	17:14:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100128	07:51:00	17:18:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f100129	07:48:00	17:15:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f11012a	07:52:00	17:19:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f11012b	07:52:00	16:42:00	EARLY	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f13012c	07:53:00	17:20:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f13012d	07:53:00	17:10:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f13012e	07:53:00	17:20:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f13012f	07:52:00	17:09:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130130	07:50:00	\N	MISSING	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130131	07:51:00	17:08:00	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130132	07:49:00	17:06:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130133	07:48:00	17:05:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130134	07:50:00	17:07:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130135	07:51:00	17:08:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130136	07:56:00	17:13:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130137	07:52:00	17:19:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130138	07:49:00	17:16:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f130139	07:51:00	17:18:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f14013a	07:52:00	16:43:00	EARLY	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f14013b	07:52:00	17:19:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f14013c	07:54:00	17:11:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f14013d	07:54:00	17:21:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f14013e	07:53:00	17:10:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f14013f	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f140140	07:52:00	17:09:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f140141	07:50:00	17:07:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f140142	07:49:00	17:06:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f150143	07:51:00	17:08:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f150144	07:52:00	17:09:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f150145	07:55:00	17:12:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f150146	07:53:00	17:20:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f150147	07:50:00	17:17:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f150148	07:50:00	17:17:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160149	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16014a	07:51:00	17:18:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16014b	07:55:00	17:12:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16014c	07:55:00	17:22:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16014d	07:54:00	17:11:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16014e	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16014f	07:53:00	17:10:00	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160150	07:51:00	17:08:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160151	07:50:00	17:07:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160152	07:52:00	17:09:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160153	07:53:00	17:10:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160154	07:54:00	17:11:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160155	07:54:00	17:21:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160156	07:51:00	17:18:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160157	07:49:00	17:16:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160158	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f160159	07:50:00	17:17:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16015a	\N	\N	PAID_LEAVE	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16015b	07:56:00	17:23:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16015c	07:55:00	17:12:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16015d	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f16015e	07:54:00	17:11:00	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f17015f	07:52:00	17:09:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170160	\N	\N	PAID_LEAVE	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170161	07:53:00	17:10:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170162	07:54:00	17:11:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170163	07:53:00	17:10:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170164	07:55:00	17:22:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170165	07:52:00	17:19:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170166	07:48:00	17:15:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170167	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170168	07:49:00	17:16:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f170169	\N	\N	PAID_LEAVE	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f17016a	\N	\N	PAID_LEAVE	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f18016b	07:56:00	17:13:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f18016c	07:52:00	16:43:00	EARLY	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f18016d	07:55:00	17:12:00	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f18016e	07:56:00	17:13:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f18016f	07:55:00	17:12:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f180170	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f180171	07:48:00	17:15:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f180172	\N	\N	PAID_LEAVE	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f180173	08:21:00	17:16:00	LATE	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f180174	08:18:00	17:13:00	LATE	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f180175	07:54:00	17:11:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f180176	07:53:00	17:20:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f190177	07:52:00	16:42:00	EARLY	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f190178	07:50:00	\N	MISSING	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f190179	08:23:00	17:18:00	LATE	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f19017a	07:50:00	17:17:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f19017b	07:52:00	17:09:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f19017c	07:49:00	17:16:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f19017d	07:57:00	17:14:00	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f19017e	07:56:00	17:13:00	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f20017f	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2c0180	07:49:00	17:16:00	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2c0181	\N	\N	PAID_LEAVE	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2c0182	08:22:00	17:17:00	LATE	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2c0183	08:19:00	17:14:00	LATE	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2c0184	07:53:00	17:10:00	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0185	07:54:00	17:21:00	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0186	07:52:00	16:41:00	EARLY	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0187	07:50:00	\N	MISSING	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0188	07:52:00	16:39:00	EARLY	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0189	07:51:00	17:18:00	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e018a	07:51:00	17:08:00	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e018b	07:50:00	17:17:00	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e018c	07:48:00	17:15:00	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e018d	07:57:00	17:14:00	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e018e	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e018f	07:50:00	17:17:00	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0190	08:19:00	17:14:00	LATE	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0191	08:23:00	17:18:00	LATE	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0192	\N	\N	PAID_LEAVE	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0193	07:52:00	17:09:00	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0194	07:55:00	17:22:00	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0195	07:52:00	16:40:00	EARLY	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0196	07:50:00	\N	MISSING	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0197	07:52:00	16:40:00	EARLY	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0198	07:52:00	17:19:00	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e0199	07:50:00	17:07:00	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e019a	07:51:00	17:18:00	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e019b	07:49:00	17:16:00	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e019c	07:48:00	17:15:00	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e019d	07:50:00	\N	MISSING	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e019e	07:51:00	17:18:00	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e019f	08:18:00	17:13:00	LATE	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a0	07:52:00	16:39:00	EARLY	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a1	\N	\N	PAID_LEAVE	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a2	07:51:00	17:08:00	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a3	07:56:00	17:23:00	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a4	07:52:00	16:39:00	EARLY	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a5	\N	\N	BUSINESS_TRIP	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a6	07:52:00	16:41:00	EARLY	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a7	07:53:00	17:20:00	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a8	07:49:00	17:06:00	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01a9	07:52:00	17:19:00	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01aa	07:50:00	17:17:00	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01ab	07:49:00	17:16:00	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01ac	07:50:00	\N	MISSING	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01ad	07:52:00	17:19:00	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01ae	08:17:00	17:12:00	LATE	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01af	07:52:00	16:40:00	EARLY	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b0	08:22:00	17:17:00	LATE	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b1	07:50:00	17:07:00	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b2	07:57:00	17:24:00	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b3	08:23:00	17:18:00	LATE	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b4	\N	\N	BUSINESS_TRIP	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b5	07:52:00	16:42:00	EARLY	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b6	08:16:00	17:11:00	LATE	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b7	07:48:00	17:05:00	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b8	07:53:00	17:20:00	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01b9	07:53:00	17:20:00	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01ba	07:52:00	17:19:00	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01bb	\N	\N	BUSINESS_TRIP	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01bc	08:17:00	17:12:00	LATE	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01bd	07:52:00	17:19:00	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2e01be	07:52:00	16:43:00	EARLY	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01bf	07:52:00	16:40:00	EARLY	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c0	07:57:00	17:24:00	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c1	07:50:00	17:07:00	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c2	08:20:00	17:15:00	LATE	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c3	07:48:00	17:05:00	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c4	08:20:00	16:35:00	LATE_AND_EARLY	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c5	08:19:00	17:14:00	LATE	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c6	07:55:00	17:22:00	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c7	08:18:00	17:13:00	LATE	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c8	08:17:00	17:12:00	LATE	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01c9	\N	\N	BUSINESS_TRIP	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01ca	07:56:00	17:23:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01cb	\N	\N	UNEXCUSED_ABSENCE	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01cc	07:50:00	17:17:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01cd	07:48:00	17:15:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01ce	07:55:00	17:12:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01cf	07:55:00	17:22:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d0	07:52:00	17:09:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d1	07:56:00	17:23:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d2	07:50:00	17:07:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d3	07:50:00	17:17:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d4	07:49:00	17:06:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d5	07:53:00	17:20:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d6	07:48:00	17:05:00	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d7	08:18:00	17:13:00	LATE	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d8	\N	\N	BUSINESS_TRIP	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01d9	07:57:00	17:24:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01da	07:48:00	17:05:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01db	07:49:00	17:16:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01dc	07:49:00	17:16:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01dd	07:56:00	17:13:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01de	07:54:00	17:21:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01df	07:53:00	17:10:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e0	07:55:00	17:22:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e1	07:51:00	17:08:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e2	07:51:00	17:18:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e3	07:50:00	17:07:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e4	07:52:00	17:19:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e5	07:49:00	17:06:00	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e6	08:19:00	17:14:00	LATE	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e7	\N	\N	UNEXCUSED_ABSENCE	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e8	07:48:00	17:05:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01e9	07:49:00	17:06:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01ea	07:48:00	17:15:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01eb	07:50:00	17:17:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01ec	07:57:00	17:14:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01ed	07:53:00	17:20:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01ee	07:54:00	17:11:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01ef	07:54:00	17:21:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f0	07:52:00	17:09:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f1	07:52:00	17:19:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f2	07:51:00	17:08:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f3	07:51:00	17:18:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f4	07:50:00	17:07:00	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f5	08:20:00	17:15:00	LATE	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f6	\N	\N	UNEXCUSED_ABSENCE	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f7	07:49:00	17:06:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f8	07:50:00	17:07:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01f9	07:57:00	17:14:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01fa	07:51:00	17:18:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01fb	07:48:00	17:15:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01fc	07:52:00	17:19:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01fd	07:55:00	17:12:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01fe	07:53:00	17:20:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f01ff	07:53:00	17:10:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f0200	07:53:00	17:20:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f0201	07:52:00	17:09:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f2f0202	07:50:00	17:17:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300203	07:51:00	17:08:00	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300204	08:23:00	17:18:00	LATE	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300205	07:50:00	17:07:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300206	07:52:00	17:09:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300207	07:53:00	17:10:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300208	07:54:00	17:11:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300209	07:54:00	17:21:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30020a	07:51:00	17:18:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30020b	07:49:00	17:16:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30020c	07:48:00	17:15:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30020d	07:50:00	17:17:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30020e	07:56:00	17:13:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30020f	07:56:00	17:23:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300210	07:55:00	17:12:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300211	07:57:00	17:14:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300212	07:54:00	17:11:00	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300213	07:52:00	16:39:00	EARLY	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300214	07:51:00	17:08:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300215	07:53:00	17:10:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300216	07:54:00	17:11:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300217	07:53:00	17:10:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300218	07:55:00	17:22:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300219	07:52:00	17:19:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30021a	07:48:00	17:15:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30021b	07:49:00	17:16:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30021c	07:49:00	17:16:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30021d	07:57:00	17:14:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30021e	07:57:00	17:24:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30021f	07:56:00	17:13:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300220	07:56:00	17:13:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300221	07:55:00	17:12:00	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300222	07:52:00	16:40:00	EARLY	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300223	07:52:00	17:09:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300224	07:54:00	17:11:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300225	07:55:00	17:12:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300226	07:52:00	17:09:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300227	07:56:00	17:23:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300228	07:53:00	17:20:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300229	07:57:00	17:14:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30022a	07:50:00	17:17:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30022b	07:48:00	17:15:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30022c	07:48:00	17:15:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30022d	07:48:00	17:05:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30022e	07:57:00	17:14:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30022f	07:55:00	17:12:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300230	07:56:00	17:13:00	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300231	07:52:00	16:41:00	EARLY	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300232	07:53:00	17:10:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300233	07:55:00	17:12:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300234	07:56:00	17:13:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300235	07:51:00	17:08:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300236	07:57:00	17:24:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300237	07:54:00	17:21:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300238	07:56:00	17:13:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300239	07:51:00	17:18:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30023a	07:57:00	17:14:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30023b	07:49:00	17:16:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30023c	07:49:00	17:06:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30023d	07:48:00	17:15:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30023e	07:54:00	17:11:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30023f	07:57:00	17:14:00	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300240	07:56:00	17:13:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300241	07:55:00	17:12:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300242	07:57:00	17:14:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300243	07:48:00	17:15:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300244	07:49:00	17:06:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300245	07:49:00	17:06:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300246	07:56:00	17:23:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300247	07:52:00	16:41:00	EARLY	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300248	07:53:00	17:20:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f300249	07:55:00	17:12:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30024a	07:51:00	17:18:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30024b	07:51:00	17:08:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30024c	07:50:00	17:17:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30024d	07:52:00	17:09:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30024e	07:49:00	17:16:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f30024f	07:56:00	17:13:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310250	07:55:00	17:12:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310251	07:57:00	17:14:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310252	07:48:00	17:15:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310253	07:49:00	17:06:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310254	07:49:00	17:06:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310255	07:56:00	17:23:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310256	07:52:00	16:41:00	EARLY	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310257	07:53:00	17:20:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310258	07:55:00	17:12:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310259	07:51:00	17:18:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31025a	07:51:00	17:08:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31025b	07:50:00	17:17:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31025c	07:52:00	17:09:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31025d	07:49:00	17:16:00	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31025e	07:57:00	17:14:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31025f	07:56:00	17:13:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310260	07:48:00	17:15:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310261	07:49:00	17:16:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310262	07:48:00	17:05:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310263	07:50:00	17:07:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310264	07:57:00	17:24:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310265	07:52:00	16:40:00	EARLY	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310266	08:16:00	17:11:00	LATE	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310267	07:54:00	17:11:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310268	07:52:00	17:19:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310269	07:52:00	17:09:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31026a	07:51:00	17:18:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31026b	07:51:00	17:08:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31026c	07:50:00	17:17:00	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31026d	07:48:00	17:15:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31026e	07:57:00	17:14:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31026f	07:49:00	17:16:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310270	07:50:00	17:17:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310271	07:57:00	17:24:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310272	07:51:00	17:08:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310273	07:48:00	17:05:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310274	07:52:00	16:39:00	EARLY	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310275	08:17:00	17:12:00	LATE	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310276	07:53:00	17:10:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310277	07:53:00	17:20:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310278	07:53:00	17:10:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310279	07:52:00	17:19:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31027a	07:50:00	17:07:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31027b	07:51:00	17:18:00	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31027c	07:49:00	17:16:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31027d	07:48:00	17:15:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31027e	07:50:00	17:17:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f31027f	07:51:00	17:18:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310280	07:56:00	17:23:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310281	07:52:00	17:09:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310282	07:49:00	17:06:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f310283	08:23:00	17:18:00	LATE	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330284	08:18:00	17:13:00	LATE	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330285	07:52:00	17:09:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330286	07:54:00	17:21:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330287	07:54:00	17:11:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330288	07:53:00	17:20:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330289	07:49:00	17:06:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33028a	07:52:00	17:19:00	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33028b	07:50:00	17:17:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33028c	07:49:00	17:16:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33028d	07:51:00	17:18:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33028e	07:52:00	17:19:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33028f	07:55:00	17:22:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330290	07:53:00	17:10:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330291	07:50:00	17:07:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330292	08:22:00	17:17:00	LATE	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330293	08:19:00	17:14:00	LATE	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330294	07:51:00	17:08:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330295	07:55:00	17:22:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330296	07:55:00	17:12:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330297	07:54:00	17:21:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330298	07:48:00	17:05:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f330299	07:53:00	17:20:00	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33029a	07:53:00	17:20:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33029b	07:52:00	17:19:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33029c	07:54:00	17:21:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33029d	07:55:00	17:22:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33029e	07:52:00	17:19:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f33029f	07:56:00	17:13:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3302a0	07:53:00	17:10:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3302a1	08:19:00	17:14:00	LATE	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3302a2	08:22:00	17:17:00	LATE	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3302a3	07:48:00	17:05:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3302a4	07:48:00	17:05:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3302a5	07:48:00	17:15:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3302a6	07:57:00	17:24:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402a7	\N	\N	BUSINESS_TRIP	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402a8	07:56:00	17:23:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402a9	07:55:00	17:22:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402aa	07:54:00	17:21:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ab	08:18:00	17:13:00	LATE	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ac	07:57:00	17:24:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ad	07:50:00	\N	MISSING	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ae	07:48:00	17:15:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402af	07:55:00	17:12:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b0	07:55:00	17:22:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b1	07:52:00	17:09:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b2	\N	\N	UNEXCUSED_ABSENCE	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b3	08:22:00	17:17:00	LATE	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b4	07:50:00	17:17:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b5	07:49:00	17:06:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b6	07:53:00	17:20:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b7	07:48:00	17:05:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b8	07:56:00	17:23:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402b9	07:55:00	17:22:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ba	08:19:00	17:14:00	LATE	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402bb	07:48:00	17:05:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402bc	08:20:00	16:35:00	LATE_AND_EARLY	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402bd	07:49:00	17:16:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402be	07:56:00	17:13:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402bf	07:54:00	17:21:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c0	07:53:00	17:10:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c1	\N	\N	BUSINESS_TRIP	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c2	08:23:00	17:18:00	LATE	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c3	07:51:00	17:18:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c4	07:50:00	17:07:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c5	07:52:00	17:19:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c6	07:49:00	17:06:00	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c7	07:57:00	17:24:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c8	07:56:00	17:23:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402c9	08:20:00	17:15:00	LATE	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ca	07:49:00	17:06:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402cb	08:20:00	16:35:00	LATE_AND_EARLY	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402cc	07:50:00	17:17:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402cd	07:57:00	17:14:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ce	07:53:00	17:20:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402cf	07:54:00	17:11:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d0	\N	\N	BUSINESS_TRIP	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d1	07:52:00	16:39:00	EARLY	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d2	07:52:00	17:19:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d3	07:51:00	17:08:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d4	07:51:00	17:18:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d5	07:50:00	17:07:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d6	07:48:00	17:05:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d7	07:57:00	17:24:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d8	08:21:00	17:16:00	LATE	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402d9	07:50:00	17:07:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402da	08:20:00	16:35:00	LATE_AND_EARLY	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402db	07:51:00	17:18:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402dc	07:48:00	17:15:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402dd	07:52:00	17:19:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402de	07:55:00	17:12:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402df	07:50:00	\N	MISSING	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e0	07:52:00	16:40:00	EARLY	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e1	07:53:00	17:20:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e2	07:52:00	17:09:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e3	07:50:00	17:17:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e4	07:51:00	17:08:00	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e5	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e6	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e7	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e8	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402e9	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ea	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402eb	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ec	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ed	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ee	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ef	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f0	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f1	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f2	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f3	\N	\N	HOLIDAY	2026-02-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f4	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f5	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f6	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f7	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f8	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402f9	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402fa	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402fb	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402fc	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402fd	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402fe	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f3402ff	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f340300	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f340301	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89249f340302	\N	\N	HOLIDAY	2026-02-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40303	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40304	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40305	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40306	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40307	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40308	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40309	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4030a	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4030b	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4030c	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4030d	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4030e	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4030f	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40310	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40311	\N	\N	HOLIDAY	2026-02-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40312	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40313	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40314	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40315	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40316	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40317	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40318	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40319	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4031a	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4031b	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4031c	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4031d	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4031e	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4031f	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40320	\N	\N	HOLIDAY	2026-02-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40321	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40322	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40323	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40324	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40325	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40326	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40327	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40328	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40329	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4032a	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4032b	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4032c	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4032d	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4032e	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4032f	\N	\N	HOLIDAY	2026-02-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40330	07:49:00	17:16:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40331	08:20:00	16:35:00	LATE_AND_EARLY	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40332	07:50:00	17:17:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40333	07:50:00	\N	MISSING	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40334	07:56:00	17:23:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40335	07:52:00	17:09:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40336	07:49:00	17:06:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40337	07:51:00	17:08:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40338	07:56:00	17:23:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40339	07:52:00	17:09:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4033a	07:54:00	17:21:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4033b	07:54:00	17:11:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4033c	07:50:00	\N	MISSING	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4033d	07:49:00	17:06:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4033e	07:50:00	\N	MISSING	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4033f	07:50:00	17:17:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40340	08:20:00	16:35:00	LATE_AND_EARLY	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40341	07:51:00	17:18:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40342	07:50:00	\N	MISSING	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40343	07:55:00	17:22:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40344	07:53:00	17:10:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40345	07:50:00	17:07:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40346	07:50:00	17:07:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40347	07:57:00	17:24:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40348	07:51:00	17:08:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40349	07:55:00	17:22:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4034a	07:55:00	17:12:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4034b	\N	\N	BUSINESS_TRIP	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4034c	07:48:00	17:05:00	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4034d	07:50:00	\N	MISSING	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4034e	07:51:00	17:18:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4034f	07:50:00	\N	MISSING	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40350	07:52:00	17:19:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40351	07:50:00	\N	MISSING	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40352	07:54:00	17:21:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40353	07:54:00	17:11:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40354	07:51:00	17:08:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40355	07:49:00	17:06:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40356	07:48:00	17:05:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40357	07:50:00	17:07:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40358	07:56:00	17:23:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c40359	07:56:00	17:13:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4035a	\N	\N	BUSINESS_TRIP	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4035b	07:57:00	17:24:00	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c4035c	\N	\N	BUSINESS_TRIP	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5035d	07:52:00	17:19:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5035e	07:50:00	\N	MISSING	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5035f	07:53:00	17:20:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50360	\N	\N	BUSINESS_TRIP	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50361	07:53:00	17:20:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50362	07:55:00	17:12:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50363	07:52:00	17:09:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50364	07:48:00	17:05:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50365	07:49:00	17:06:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50366	07:49:00	17:06:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50367	07:57:00	17:24:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50368	07:57:00	17:14:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50369	\N	\N	UNEXCUSED_ABSENCE	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5036a	07:56:00	17:23:00	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5036b	\N	\N	BUSINESS_TRIP	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5036c	07:53:00	17:20:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5036d	07:50:00	\N	MISSING	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5036e	07:54:00	17:21:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5036f	\N	\N	BUSINESS_TRIP	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50370	07:52:00	17:19:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50371	07:56:00	17:13:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50372	07:53:00	17:10:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50373	07:57:00	17:24:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50374	07:50:00	17:07:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50375	07:48:00	17:05:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50376	07:48:00	17:05:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50377	07:48:00	17:15:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50378	\N	\N	UNEXCUSED_ABSENCE	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50379	07:55:00	17:22:00	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5037a	\N	\N	UNEXCUSED_ABSENCE	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5037b	\N	\N	UNEXCUSED_ABSENCE	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5037c	07:56:00	17:23:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5037d	07:48:00	17:05:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5037e	07:49:00	17:06:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5037f	07:48:00	17:15:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50380	07:50:00	17:17:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50381	07:57:00	17:14:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50382	07:50:00	\N	MISSING	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50383	07:54:00	17:11:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50384	07:54:00	17:21:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50385	07:52:00	17:09:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50386	07:52:00	17:19:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50387	07:51:00	17:08:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50388	07:51:00	17:18:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50389	07:50:00	17:07:00	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5038a	07:48:00	17:05:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5038b	07:57:00	17:24:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5038c	07:49:00	17:06:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5038d	07:50:00	17:07:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5038e	07:57:00	17:14:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5038f	07:51:00	17:18:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50390	07:48:00	17:15:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50391	07:50:00	\N	MISSING	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50392	07:55:00	17:12:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50393	07:53:00	17:20:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50394	07:53:00	17:10:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50395	07:53:00	17:20:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50396	07:52:00	17:09:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50397	07:50:00	17:17:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50398	07:51:00	17:08:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c50399	07:49:00	17:06:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5039a	07:48:00	17:05:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5039b	07:50:00	17:07:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5039c	07:51:00	17:08:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5039d	07:56:00	17:13:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5039e	07:52:00	17:19:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c5039f	07:49:00	17:16:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a0	07:50:00	\N	MISSING	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a1	07:56:00	17:13:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a2	07:52:00	17:19:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a3	07:54:00	17:11:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a4	07:54:00	17:21:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a5	07:53:00	17:10:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a6	07:49:00	17:16:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a7	07:52:00	17:09:00	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a8	07:50:00	17:07:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503a9	07:49:00	17:06:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503aa	07:51:00	17:08:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503ab	07:52:00	17:09:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503ac	07:55:00	17:12:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503ad	07:53:00	17:20:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503ae	07:50:00	17:17:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503af	07:50:00	\N	MISSING	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b0	07:57:00	17:14:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b1	07:51:00	17:18:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b2	07:55:00	17:12:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b3	07:55:00	17:22:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b4	07:54:00	17:11:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b5	07:48:00	17:15:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b6	07:53:00	17:10:00	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b7	07:51:00	17:08:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b8	07:50:00	17:07:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503b9	07:52:00	17:09:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503ba	07:53:00	17:10:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503bb	07:54:00	17:11:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503bc	07:54:00	17:21:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503bd	07:51:00	17:18:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503be	08:20:00	16:35:00	LATE_AND_EARLY	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503bf	07:48:00	17:15:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503c0	07:50:00	17:17:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503c1	07:56:00	17:13:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c503c2	07:56:00	17:23:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603c3	07:55:00	17:12:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603c4	07:57:00	17:14:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603c5	07:54:00	17:11:00	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603c6	07:54:00	17:11:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603c7	07:53:00	17:10:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603c8	07:55:00	17:12:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603c9	07:56:00	17:13:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603ca	07:51:00	17:08:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603cb	07:57:00	17:24:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603cc	07:54:00	17:21:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603cd	07:52:00	16:43:00	EARLY	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603ce	07:51:00	17:18:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603cf	07:57:00	17:14:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d0	07:49:00	17:16:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d1	07:49:00	17:06:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d2	07:48:00	17:15:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d3	07:54:00	17:11:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d4	07:57:00	17:14:00	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d5	07:56:00	17:13:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d6	07:55:00	17:12:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d7	07:57:00	17:14:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d8	07:48:00	17:15:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603d9	07:49:00	17:06:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603da	07:49:00	17:06:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603db	07:56:00	17:23:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603dc	07:54:00	17:11:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603dd	07:50:00	\N	MISSING	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603de	07:55:00	17:12:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603df	07:51:00	17:18:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e0	07:51:00	17:08:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e1	\N	\N	PAID_LEAVE	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e2	07:52:00	16:39:00	EARLY	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e3	07:49:00	17:16:00	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e4	07:57:00	17:14:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e5	07:56:00	17:13:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e6	07:48:00	17:15:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e7	\N	\N	PAID_LEAVE	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e8	07:48:00	17:05:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603e9	07:50:00	17:07:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603ea	07:57:00	17:24:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603eb	07:53:00	17:10:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603ec	\N	\N	BUSINESS_TRIP	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603ed	07:54:00	17:11:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603ee	07:52:00	17:19:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603ef	07:52:00	17:09:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f0	\N	\N	PAID_LEAVE	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f1	\N	\N	PAID_LEAVE	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f2	07:50:00	17:17:00	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f3	07:48:00	17:15:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f4	07:57:00	17:14:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f5	07:49:00	17:16:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f6	07:50:00	17:17:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f7	\N	\N	UNEXCUSED_ABSENCE	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f8	07:51:00	17:08:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603f9	07:48:00	17:05:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603fa	07:52:00	17:09:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603fb	\N	\N	BUSINESS_TRIP	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603fc	07:53:00	17:10:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603fd	07:53:00	17:20:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603fe	07:53:00	17:10:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c603ff	07:52:00	17:19:00	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60400	08:22:00	17:17:00	LATE	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60401	\N	\N	PAID_LEAVE	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60402	07:49:00	17:16:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60403	07:48:00	17:15:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60404	07:50:00	17:17:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60405	07:51:00	17:18:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60406	\N	\N	UNEXCUSED_ABSENCE	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60407	\N	\N	PAID_LEAVE	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60408	07:49:00	17:06:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60409	07:51:00	17:08:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6040a	\N	\N	UNEXCUSED_ABSENCE	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6040b	07:52:00	17:09:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6040c	08:16:00	17:11:00	LATE	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6040d	07:54:00	17:11:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6040e	07:53:00	17:20:00	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6040f	08:21:00	17:16:00	LATE	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60410	\N	\N	PAID_LEAVE	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60411	07:52:00	17:19:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60412	07:51:00	17:18:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60413	07:53:00	17:20:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60414	07:54:00	17:21:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60415	07:50:00	\N	MISSING	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60416	07:55:00	17:12:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60417	07:52:00	17:09:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60418	07:48:00	17:05:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60419	\N	\N	PAID_LEAVE	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6041a	07:49:00	17:06:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6041b	08:19:00	17:14:00	LATE	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6041c	07:57:00	17:14:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6041d	07:56:00	17:23:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6041e	08:18:00	17:13:00	LATE	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6041f	07:55:00	17:22:00	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60420	07:53:00	17:20:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60421	07:52:00	17:19:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60422	08:16:00	17:11:00	LATE	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60423	07:55:00	17:22:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60424	07:50:00	\N	MISSING	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60425	07:56:00	17:13:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60426	07:53:00	17:10:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60427	07:57:00	17:24:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60428	\N	\N	PAID_LEAVE	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60429	\N	\N	PAID_LEAVE	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6042a	08:20:00	17:15:00	LATE	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6042b	07:48:00	17:15:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6042c	07:57:00	17:24:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6042d	08:17:00	17:12:00	LATE	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6042e	07:56:00	17:23:00	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6042f	07:54:00	17:21:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60430	07:53:00	17:20:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60431	08:17:00	17:12:00	LATE	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60432	07:56:00	17:23:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60433	07:50:00	\N	MISSING	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60434	07:57:00	17:14:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30060f	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60435	07:54:00	17:11:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60436	07:56:00	17:23:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60437	07:51:00	17:08:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60438	\N	\N	UNEXCUSED_ABSENCE	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60439	08:21:00	17:16:00	LATE	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6043a	07:49:00	17:16:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6043b	07:48:00	17:05:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6043c	08:16:00	17:11:00	LATE	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6043d	07:57:00	17:24:00	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6043e	07:55:00	17:22:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6043f	07:54:00	17:21:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60440	08:18:00	17:13:00	LATE	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60441	07:57:00	17:24:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60442	07:50:00	\N	MISSING	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60443	07:48:00	17:15:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60444	07:55:00	17:12:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60445	07:55:00	17:22:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60446	07:52:00	17:09:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60447	\N	\N	UNEXCUSED_ABSENCE	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60448	08:22:00	17:17:00	LATE	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60449	07:50:00	17:17:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6044a	07:49:00	17:06:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6044b	07:53:00	17:20:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6044c	07:48:00	17:05:00	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6044d	07:57:00	17:24:00	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6044e	08:18:00	17:13:00	LATE	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6044f	07:48:00	17:05:00	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60450	08:21:00	17:16:00	LATE	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60451	07:48:00	17:15:00	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60452	07:50:00	\N	MISSING	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60453	08:20:00	16:35:00	LATE_AND_EARLY	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60454	07:53:00	17:20:00	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60455	07:54:00	17:11:00	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60456	08:16:00	17:11:00	LATE	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60457	07:52:00	17:09:00	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60458	07:50:00	\N	MISSING	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60459	08:23:00	17:18:00	LATE	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6045a	07:51:00	17:18:00	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6045b	08:22:00	17:17:00	LATE	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6045c	07:50:00	17:07:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6045d	08:21:00	17:16:00	LATE	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6045e	07:51:00	17:08:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c6045f	07:52:00	16:39:00	EARLY	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60460	07:55:00	17:12:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60461	07:50:00	\N	MISSING	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60462	07:50:00	\N	MISSING	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60463	07:50:00	17:17:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c60464	07:57:00	17:14:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80465	07:51:00	17:18:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80466	07:55:00	17:12:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80467	\N	\N	BUSINESS_TRIP	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80468	07:52:00	16:41:00	EARLY	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80469	07:48:00	17:15:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8046a	07:52:00	16:40:00	EARLY	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8046b	07:51:00	17:08:00	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8046c	08:22:00	17:17:00	LATE	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8046d	07:52:00	17:09:00	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8046e	07:52:00	16:40:00	EARLY	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8046f	07:54:00	17:11:00	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80470	\N	\N	BUSINESS_TRIP	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80471	07:50:00	\N	MISSING	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80472	07:49:00	17:16:00	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80473	07:48:00	17:15:00	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80474	07:50:00	17:17:00	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80475	07:56:00	17:13:00	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80476	\N	\N	UNEXCUSED_ABSENCE	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80477	07:52:00	16:42:00	EARLY	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80478	07:57:00	17:14:00	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80479	07:52:00	16:41:00	EARLY	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8047a	07:52:00	17:09:00	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8047b	08:23:00	17:18:00	LATE	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8047c	07:53:00	17:10:00	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8047d	07:52:00	16:41:00	EARLY	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8047e	07:53:00	17:10:00	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8047f	\N	\N	BUSINESS_TRIP	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80480	07:50:00	\N	MISSING	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80481	07:48:00	17:15:00	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80482	07:49:00	17:16:00	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80483	07:49:00	17:16:00	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80484	07:57:00	17:14:00	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80485	\N	\N	UNEXCUSED_ABSENCE	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80486	07:52:00	16:43:00	EARLY	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80487	07:56:00	17:13:00	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80488	07:52:00	16:42:00	EARLY	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80489	07:53:00	17:10:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8048a	07:52:00	16:39:00	EARLY	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8048b	07:54:00	17:11:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8048c	07:52:00	16:42:00	EARLY	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8048d	07:52:00	17:09:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8048e	\N	\N	UNEXCUSED_ABSENCE	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8048f	07:50:00	\N	MISSING	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80490	07:57:00	17:14:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80491	07:50:00	17:17:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80492	07:48:00	17:15:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80493	07:48:00	17:15:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80494	07:48:00	17:05:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80495	08:20:00	16:35:00	LATE_AND_EARLY	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80496	07:55:00	17:12:00	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80497	07:52:00	16:43:00	EARLY	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80498	07:54:00	17:11:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c80499	07:52:00	16:40:00	EARLY	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8049a	07:55:00	17:12:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8049b	07:52:00	16:43:00	EARLY	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8049c	07:51:00	17:08:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8049d	\N	\N	UNEXCUSED_ABSENCE	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8049e	\N	\N	BUSINESS_TRIP	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c8049f	07:56:00	17:13:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a0	07:51:00	17:18:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a1	07:57:00	17:14:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a2	07:49:00	17:16:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a3	07:49:00	17:06:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a4	08:20:00	16:35:00	LATE_AND_EARLY	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a5	07:54:00	17:11:00	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a6	08:20:00	16:35:00	LATE_AND_EARLY	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a7	08:20:00	16:35:00	LATE_AND_EARLY	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a8	07:57:00	17:14:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804a9	07:49:00	17:16:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804aa	07:50:00	17:17:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804ab	07:57:00	17:24:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804ac	07:51:00	17:08:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804ad	07:48:00	17:05:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804ae	07:52:00	17:09:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804af	07:55:00	17:22:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b0	07:53:00	17:10:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b1	07:53:00	17:20:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b2	07:53:00	17:10:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b3	07:52:00	17:19:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b4	07:50:00	17:07:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b5	07:51:00	17:18:00	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b6	08:20:00	16:35:00	LATE_AND_EARLY	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b7	07:48:00	17:15:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b8	07:50:00	17:17:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804b9	07:51:00	17:18:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804ba	07:56:00	17:23:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804bb	07:52:00	17:09:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804bc	07:49:00	17:06:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804bd	07:51:00	17:08:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804be	07:56:00	17:23:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c804bf	07:52:00	17:09:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c0	07:54:00	17:21:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c1	07:54:00	17:11:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c2	07:53:00	17:20:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c3	07:49:00	17:06:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c4	07:52:00	17:19:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c5	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c6	07:56:00	17:13:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c7	07:48:00	17:15:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c8	07:49:00	17:16:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904c9	07:48:00	17:05:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904ca	07:50:00	17:07:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904cb	07:57:00	17:24:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904cc	07:53:00	17:10:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904cd	07:54:00	17:21:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904ce	07:54:00	17:11:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904cf	07:52:00	17:19:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d0	07:52:00	17:09:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d1	07:51:00	17:18:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d2	07:51:00	17:08:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d3	07:50:00	17:17:00	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d4	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d5	07:57:00	17:14:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d6	07:49:00	17:16:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d7	07:50:00	17:17:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d8	07:57:00	17:24:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904d9	07:51:00	17:08:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904da	07:48:00	17:05:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904db	07:52:00	17:09:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904dc	07:55:00	17:22:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904dd	07:53:00	17:10:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904de	07:53:00	17:20:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904df	07:53:00	17:10:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e0	07:52:00	17:19:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e1	07:50:00	17:07:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e2	07:51:00	17:18:00	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e3	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e4	07:48:00	17:15:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e5	07:50:00	17:17:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e6	07:51:00	17:18:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e7	07:56:00	17:23:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e8	07:52:00	17:09:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904e9	07:49:00	17:06:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904ea	07:51:00	17:08:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904eb	07:56:00	17:23:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904ec	07:52:00	17:09:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904ed	07:54:00	17:21:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904ee	07:54:00	17:11:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904ef	07:53:00	17:20:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f0	07:49:00	17:06:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f1	07:52:00	17:19:00	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f2	07:50:00	\N	MISSING	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f3	07:51:00	17:18:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f4	07:53:00	17:20:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f5	07:54:00	17:21:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f6	07:53:00	17:20:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f7	07:55:00	17:12:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f8	07:52:00	17:09:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904f9	07:48:00	17:05:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904fa	07:49:00	17:06:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904fb	07:49:00	17:06:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904fc	07:57:00	17:24:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904fd	07:57:00	17:14:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904fe	07:56:00	17:23:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c904ff	07:56:00	17:23:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924b3c90500	07:55:00	17:22:00	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0501	07:50:00	\N	MISSING	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0502	07:52:00	17:19:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0503	07:54:00	17:21:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0504	07:55:00	17:22:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0505	07:52:00	17:19:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0506	07:56:00	17:13:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0507	07:53:00	17:10:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0508	\N	\N	UNEXCUSED_ABSENCE	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0509	07:50:00	17:07:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d050a	07:48:00	17:05:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d050b	07:48:00	17:05:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d050c	07:48:00	17:15:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d050d	07:57:00	17:24:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d050e	07:55:00	17:22:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d050f	07:56:00	17:23:00	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0510	\N	\N	PAID_LEAVE	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0511	07:53:00	17:20:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0512	07:55:00	17:22:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0513	07:56:00	17:23:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0514	07:51:00	17:18:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0515	07:57:00	17:14:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0516	07:54:00	17:11:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0517	\N	\N	UNEXCUSED_ABSENCE	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0518	07:51:00	17:08:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0519	07:57:00	17:24:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d051a	07:49:00	17:06:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d051b	07:49:00	17:16:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d051c	07:48:00	17:05:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d051d	07:54:00	17:21:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d051e	07:57:00	17:24:00	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d051f	\N	\N	PAID_LEAVE	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0520	07:54:00	17:21:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0521	07:56:00	17:23:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0522	07:57:00	17:24:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0523	07:50:00	17:17:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0524	07:48:00	17:15:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0525	07:55:00	17:12:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0526	\N	\N	BUSINESS_TRIP	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0527	07:52:00	17:09:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0528	07:56:00	17:23:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d0529	07:50:00	17:07:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d052a	07:50:00	17:17:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d052b	07:49:00	17:06:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d052c	07:53:00	17:20:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d052d	07:48:00	17:05:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2d052e	07:57:00	17:24:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e052f	07:56:00	17:23:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0530	\N	\N	PAID_LEAVE	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0531	07:49:00	17:06:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0532	07:48:00	17:15:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0533	07:50:00	17:17:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0534	07:57:00	17:14:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0535	07:53:00	17:20:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0536	07:52:00	16:41:00	EARLY	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0537	07:54:00	17:21:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0538	07:52:00	17:09:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0539	07:52:00	17:19:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e053a	07:51:00	17:08:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e053b	07:50:00	\N	MISSING	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e053c	07:50:00	17:07:00	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e053d	07:50:00	17:07:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e053e	07:49:00	17:06:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e053f	07:51:00	17:08:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300610	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0540	07:52:00	17:09:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0541	07:55:00	17:12:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0542	07:53:00	17:20:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0543	07:50:00	17:17:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0544	07:50:00	17:17:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0545	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0546	07:51:00	17:18:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0547	07:55:00	17:12:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0548	07:55:00	17:22:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0549	07:54:00	17:11:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e054a	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e054b	07:53:00	17:10:00	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e054c	07:51:00	17:08:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e054d	07:50:00	17:07:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e054e	07:52:00	17:09:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e054f	07:53:00	17:10:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0550	07:54:00	17:11:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0551	07:54:00	17:21:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0552	07:51:00	17:18:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0553	07:49:00	17:16:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0554	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0555	07:50:00	17:17:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0556	07:56:00	17:13:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0557	07:56:00	17:23:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0558	07:55:00	17:12:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0559	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e055a	07:54:00	17:11:00	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e055b	07:52:00	17:09:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e055c	07:51:00	17:08:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e055d	07:53:00	17:10:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e055e	07:54:00	17:11:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e055f	07:53:00	17:10:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0560	07:55:00	17:22:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0561	07:52:00	17:19:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0562	07:48:00	17:15:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0563	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0564	07:49:00	17:16:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0565	07:57:00	17:14:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0566	07:57:00	17:24:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0567	07:56:00	17:13:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0568	07:52:00	16:43:00	EARLY	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0569	07:55:00	17:12:00	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e056a	07:53:00	17:10:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e056b	07:52:00	17:09:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e056c	07:54:00	17:11:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e056d	07:55:00	17:12:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e056e	07:52:00	17:09:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e056f	07:56:00	17:23:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0570	07:53:00	17:20:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0571	07:57:00	17:14:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0572	07:50:00	\N	MISSING	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0573	07:48:00	17:15:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0574	07:48:00	17:15:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0575	07:48:00	17:05:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0576	07:57:00	17:14:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0577	07:52:00	16:42:00	EARLY	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0578	07:56:00	17:13:00	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0579	07:54:00	17:11:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e057a	07:53:00	17:10:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e057b	07:55:00	17:12:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e057c	07:56:00	17:13:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e057d	07:51:00	17:08:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e057e	07:57:00	17:24:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e057f	07:54:00	17:21:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0580	07:56:00	17:13:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0581	07:50:00	\N	MISSING	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0582	07:57:00	17:14:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0583	07:49:00	17:16:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0584	07:49:00	17:06:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0585	07:48:00	17:15:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0586	07:52:00	16:41:00	EARLY	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0587	07:57:00	17:14:00	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0588	07:48:00	17:15:00	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0589	07:57:00	17:14:00	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e058a	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e058b	07:50:00	17:17:00	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e058c	08:19:00	17:14:00	LATE	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e058d	08:23:00	17:18:00	LATE	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e058e	08:20:00	17:15:00	LATE	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e058f	07:52:00	17:09:00	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0590	07:55:00	17:22:00	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0591	07:52:00	16:40:00	EARLY	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0592	07:50:00	\N	MISSING	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0593	07:52:00	16:40:00	EARLY	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0594	07:52:00	17:19:00	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0595	07:50:00	17:07:00	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2e0596	07:51:00	17:18:00	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f0597	07:49:00	17:16:00	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f0598	07:48:00	17:15:00	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f0599	07:50:00	\N	MISSING	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f059a	07:51:00	17:18:00	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f059b	08:18:00	17:13:00	LATE	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f059c	07:52:00	16:39:00	EARLY	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f059d	08:21:00	17:16:00	LATE	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f059e	07:51:00	17:08:00	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f059f	07:56:00	17:23:00	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a0	07:52:00	16:39:00	EARLY	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a1	\N	\N	BUSINESS_TRIP	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a2	07:52:00	16:41:00	EARLY	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a3	07:53:00	17:20:00	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a4	07:49:00	17:06:00	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a5	07:52:00	17:19:00	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a6	07:50:00	17:17:00	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a7	07:49:00	17:16:00	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a8	07:50:00	\N	MISSING	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05a9	07:52:00	17:19:00	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05aa	08:17:00	17:12:00	LATE	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ab	07:52:00	16:40:00	EARLY	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ac	08:22:00	17:17:00	LATE	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ad	07:50:00	17:07:00	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ae	07:57:00	17:24:00	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05af	08:23:00	17:18:00	LATE	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b0	\N	\N	BUSINESS_TRIP	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b1	07:52:00	16:42:00	EARLY	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b2	08:16:00	17:11:00	LATE	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b3	07:48:00	17:05:00	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b4	07:53:00	17:20:00	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b5	07:51:00	17:18:00	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b6	07:50:00	17:17:00	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b7	07:50:00	\N	MISSING	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b8	07:53:00	17:20:00	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05b9	08:16:00	17:11:00	LATE	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ba	07:52:00	16:41:00	EARLY	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05bb	08:23:00	17:18:00	LATE	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05bc	07:49:00	17:06:00	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05bd	07:48:00	17:05:00	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05be	08:22:00	17:17:00	LATE	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05bf	\N	\N	UNEXCUSED_ABSENCE	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c0	07:52:00	16:43:00	EARLY	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c1	08:17:00	17:12:00	LATE	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c2	07:57:00	17:24:00	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c3	08:16:00	17:11:00	LATE	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c4	07:52:00	17:19:00	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c5	07:51:00	17:18:00	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c6	07:50:00	\N	MISSING	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c7	08:16:00	17:11:00	LATE	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c8	07:53:00	17:20:00	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05c9	07:52:00	16:42:00	EARLY	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ca	07:52:00	16:39:00	EARLY	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05cb	07:48:00	17:05:00	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05cc	07:49:00	17:06:00	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05cd	08:21:00	17:16:00	LATE	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ce	\N	\N	UNEXCUSED_ABSENCE	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05cf	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d0	08:18:00	17:13:00	LATE	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d1	07:56:00	17:23:00	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d2	08:17:00	17:12:00	LATE	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d3	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d4	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d5	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d6	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d7	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d8	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05d9	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05da	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05db	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05dc	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05dd	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05de	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05df	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e0	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e1	\N	\N	HOLIDAY	2026-04-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e2	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e3	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e4	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e5	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e6	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e7	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e8	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05e9	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ea	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05eb	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ec	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ed	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ee	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05ef	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f0	\N	\N	HOLIDAY	2026-04-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f1	07:56:00	17:23:00	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f2	08:17:00	17:12:00	LATE	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f3	\N	\N	UNEXCUSED_ABSENCE	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f4	08:20:00	17:15:00	LATE	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f5	07:49:00	17:16:00	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f6	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f7	07:52:00	16:43:00	EARLY	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f8	07:54:00	17:21:00	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05f9	07:53:00	17:10:00	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05fa	08:17:00	17:12:00	LATE	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05fb	07:51:00	17:08:00	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb2f05fc	07:50:00	\N	MISSING	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3005fd	08:22:00	17:17:00	LATE	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3005fe	07:52:00	17:19:00	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3005ff	08:21:00	17:16:00	LATE	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300600	07:57:00	17:24:00	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300601	08:18:00	17:13:00	LATE	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300602	07:48:00	17:05:00	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300603	08:21:00	17:16:00	LATE	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300604	07:48:00	17:15:00	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300605	07:50:00	\N	MISSING	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300606	08:20:00	16:35:00	LATE_AND_EARLY	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300607	07:53:00	17:20:00	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300608	07:54:00	17:11:00	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300609	08:16:00	17:11:00	LATE	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30060a	07:52:00	17:09:00	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30060b	07:50:00	\N	MISSING	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30060c	08:23:00	17:18:00	LATE	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30060d	07:51:00	17:18:00	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30060e	08:22:00	17:17:00	LATE	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300611	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300612	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300613	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300614	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300615	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300616	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300617	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300618	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300619	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30061a	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30061b	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30061c	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30061d	\N	\N	HOLIDAY	2026-04-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30061e	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30061f	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300620	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300621	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300622	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300623	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300624	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300625	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300626	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300627	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300628	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300629	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30062a	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30062b	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30062c	\N	\N	HOLIDAY	2026-05-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30062d	08:23:00	17:18:00	LATE	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30062e	07:50:00	17:07:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30062f	07:52:00	17:09:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300630	07:53:00	17:10:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300631	07:54:00	17:11:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300632	07:54:00	17:21:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300633	07:51:00	17:18:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300634	07:49:00	17:16:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300635	07:48:00	17:15:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300636	07:50:00	17:17:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300637	07:56:00	17:13:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300638	07:56:00	17:23:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300639	07:55:00	17:12:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30063a	07:57:00	17:14:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30063b	07:54:00	17:11:00	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30063c	07:52:00	16:39:00	EARLY	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30063d	07:51:00	17:08:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30063e	07:53:00	17:10:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30063f	07:54:00	17:11:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300640	07:53:00	17:10:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300641	07:55:00	17:22:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300642	07:52:00	17:19:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300643	07:48:00	17:15:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300644	07:49:00	17:16:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300645	07:49:00	17:16:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300646	07:57:00	17:14:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300647	07:57:00	17:24:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300648	07:56:00	17:13:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb300649	07:56:00	17:13:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30064a	07:55:00	17:12:00	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30064b	07:52:00	16:40:00	EARLY	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30064c	07:52:00	17:09:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30064d	07:54:00	17:11:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb30064e	07:55:00	17:12:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31064f	07:52:00	17:09:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310650	07:56:00	17:23:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310651	07:53:00	17:20:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310652	07:57:00	17:14:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310653	07:50:00	17:17:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310654	07:48:00	17:15:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310655	07:48:00	17:15:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310656	07:48:00	17:05:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310657	07:57:00	17:14:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310658	07:55:00	17:12:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310659	07:56:00	17:13:00	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31065a	07:52:00	16:41:00	EARLY	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31065b	07:53:00	17:10:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31065c	07:55:00	17:12:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31065d	07:56:00	17:13:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31065e	07:51:00	17:08:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31065f	07:57:00	17:24:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310660	07:54:00	17:21:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310661	07:56:00	17:13:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310662	07:51:00	17:18:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310663	07:57:00	17:14:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310664	07:49:00	17:16:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310665	07:49:00	17:06:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310666	07:48:00	17:15:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310667	07:54:00	17:11:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310668	07:57:00	17:14:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310669	07:52:00	16:42:00	EARLY	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31066a	07:54:00	17:11:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31066b	07:56:00	17:13:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31066c	07:57:00	17:14:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31066d	07:50:00	17:07:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31066e	07:48:00	17:05:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31066f	07:55:00	17:22:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310670	07:55:00	17:12:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310671	07:52:00	17:19:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310672	07:56:00	17:13:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310673	07:50:00	17:17:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310674	07:50:00	17:07:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310675	07:49:00	17:16:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310676	07:53:00	17:10:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310677	07:48:00	17:15:00	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310678	07:49:00	17:16:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310679	07:48:00	17:15:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31067a	07:50:00	17:17:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31067b	07:51:00	17:18:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31067c	07:56:00	17:23:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31067d	07:52:00	17:09:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31067e	07:49:00	17:06:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31067f	08:23:00	17:18:00	LATE	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310680	08:18:00	17:13:00	LATE	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310681	07:52:00	17:09:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310682	07:54:00	17:21:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310683	07:54:00	17:11:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310684	07:53:00	17:20:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310685	07:49:00	17:06:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310686	07:52:00	17:19:00	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310687	07:50:00	17:17:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310688	07:49:00	17:16:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310689	07:51:00	17:18:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31068a	07:52:00	17:19:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31068b	07:55:00	17:22:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31068c	07:53:00	17:10:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31068d	07:50:00	17:07:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31068e	08:22:00	17:17:00	LATE	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31068f	08:19:00	17:14:00	LATE	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310690	07:51:00	17:08:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310691	07:55:00	17:22:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310692	07:55:00	17:12:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310693	07:54:00	17:21:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310694	07:48:00	17:05:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310695	07:53:00	17:20:00	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310696	07:51:00	17:18:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310697	07:50:00	17:17:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310698	07:52:00	17:19:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb310699	07:53:00	17:20:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31069a	07:54:00	17:21:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31069b	07:54:00	17:11:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31069c	07:51:00	17:08:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31069d	08:21:00	17:16:00	LATE	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31069e	08:20:00	17:15:00	LATE	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb31069f	07:50:00	17:07:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a0	07:56:00	17:23:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a1	07:56:00	17:13:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a2	07:55:00	17:22:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a3	\N	\N	UNEXCUSED_ABSENCE	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a4	07:54:00	17:21:00	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a5	07:52:00	17:19:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a6	07:51:00	17:18:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a7	07:53:00	17:20:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a8	07:54:00	17:21:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106a9	07:53:00	17:20:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106aa	07:55:00	17:12:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106ab	07:52:00	17:09:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106ac	08:20:00	17:15:00	LATE	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106ad	08:21:00	17:16:00	LATE	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106ae	07:49:00	17:06:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106af	07:57:00	17:24:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b0	07:57:00	17:14:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b1	07:56:00	17:23:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b2	\N	\N	UNEXCUSED_ABSENCE	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b3	07:55:00	17:22:00	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b4	07:53:00	17:20:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b5	07:52:00	17:19:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b6	07:54:00	17:21:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b7	07:55:00	17:22:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b8	07:52:00	17:19:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106b9	07:56:00	17:13:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106ba	07:53:00	17:10:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106bb	\N	\N	PAID_LEAVE	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106bc	08:22:00	17:17:00	LATE	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106bd	07:48:00	17:05:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106be	07:48:00	17:05:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106bf	07:48:00	17:15:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c0	07:57:00	17:24:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c1	\N	\N	BUSINESS_TRIP	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c2	07:56:00	17:23:00	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c3	07:56:00	17:23:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c4	07:55:00	17:22:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c5	07:57:00	17:24:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c6	07:48:00	17:05:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c7	07:49:00	17:16:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c8	07:49:00	17:16:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106c9	07:56:00	17:13:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106ca	08:16:00	17:11:00	LATE	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106cb	07:52:00	16:40:00	EARLY	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106cc	07:55:00	17:22:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106cd	07:51:00	17:08:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106ce	07:51:00	17:18:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106cf	07:50:00	17:07:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d0	07:50:00	\N	MISSING	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d1	07:49:00	17:06:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d2	07:57:00	17:24:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d3	07:56:00	17:23:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d4	07:48:00	17:05:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d5	07:49:00	17:06:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d6	07:48:00	17:15:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d7	07:50:00	17:17:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d8	07:57:00	17:14:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106d9	07:53:00	17:20:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106da	07:52:00	16:41:00	EARLY	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106db	07:54:00	17:21:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106dc	07:52:00	17:09:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106dd	07:52:00	17:19:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106de	07:51:00	17:08:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106df	07:50:00	\N	MISSING	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106e0	07:50:00	17:07:00	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106e1	07:49:00	17:06:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106e2	07:48:00	17:05:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106e3	08:22:00	17:17:00	LATE	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106e4	07:51:00	17:08:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106e5	07:52:00	16:43:00	EARLY	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106e6	07:52:00	17:19:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3106e7	07:49:00	17:16:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306e8	07:51:00	17:18:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306e9	07:56:00	17:13:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306ea	07:50:00	\N	MISSING	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306eb	07:52:00	16:41:00	EARLY	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306ec	08:16:00	17:11:00	LATE	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306ed	07:53:00	17:10:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306ee	07:49:00	17:16:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306ef	07:52:00	17:09:00	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f0	07:50:00	17:07:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f1	07:49:00	17:06:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f2	08:23:00	17:18:00	LATE	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f3	07:52:00	17:09:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f4	07:52:00	16:42:00	EARLY	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f5	07:53:00	17:20:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f6	07:50:00	17:17:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f7	07:50:00	17:17:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f8	07:57:00	17:14:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306f9	07:50:00	\N	MISSING	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306fa	07:52:00	16:42:00	EARLY	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306fb	08:17:00	17:12:00	LATE	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306fc	07:54:00	17:11:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306fd	07:48:00	17:15:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924cb3306fe	07:53:00	17:10:00	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead606ff	07:51:00	17:08:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60700	07:50:00	17:07:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60701	07:52:00	16:39:00	EARLY	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60702	07:53:00	17:10:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60703	07:52:00	16:41:00	EARLY	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60704	08:16:00	17:11:00	LATE	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60705	07:51:00	17:18:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60706	07:49:00	17:16:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60707	07:48:00	17:15:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60708	07:50:00	\N	MISSING	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60709	07:52:00	16:43:00	EARLY	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead6070a	08:18:00	17:13:00	LATE	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead6070b	07:55:00	17:12:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead6070c	07:57:00	17:14:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead6070d	07:54:00	17:11:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead6070e	07:54:00	17:11:00	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead6070f	07:53:00	17:10:00	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60710	07:52:00	16:42:00	EARLY	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60711	07:56:00	17:13:00	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60712	08:23:00	17:18:00	LATE	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60713	08:19:00	17:14:00	LATE	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60714	08:16:00	17:11:00	LATE	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60715	07:56:00	17:13:00	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60716	07:51:00	17:18:00	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60717	08:20:00	16:35:00	LATE_AND_EARLY	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60718	08:20:00	16:35:00	LATE_AND_EARLY	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead60719	08:21:00	17:16:00	LATE	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7071a	07:48:00	17:15:00	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7071b	07:54:00	17:11:00	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7071c	07:57:00	17:14:00	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7071d	07:55:00	17:12:00	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7071e	07:54:00	17:11:00	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7071f	07:52:00	16:43:00	EARLY	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70720	07:57:00	17:14:00	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70721	08:22:00	17:17:00	LATE	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70722	08:20:00	17:15:00	LATE	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70723	08:17:00	17:12:00	LATE	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70724	07:55:00	17:12:00	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70725	07:52:00	17:19:00	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70726	07:52:00	16:43:00	EARLY	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70727	07:50:00	\N	MISSING	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70728	08:22:00	17:17:00	LATE	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70729	07:49:00	17:16:00	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7072a	07:53:00	17:10:00	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7072b	07:48:00	17:15:00	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7072c	07:56:00	17:13:00	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7072d	07:55:00	17:12:00	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7072e	08:20:00	16:35:00	LATE_AND_EARLY	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7072f	07:48:00	17:15:00	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70730	08:21:00	17:16:00	LATE	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70731	08:21:00	17:16:00	LATE	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70732	08:18:00	17:13:00	LATE	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70733	07:54:00	17:11:00	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70734	07:53:00	17:20:00	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70735	07:52:00	16:42:00	EARLY	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70736	07:50:00	\N	MISSING	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70737	08:23:00	17:18:00	LATE	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70738	07:50:00	17:17:00	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70739	07:52:00	17:09:00	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7073a	07:49:00	17:16:00	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7073b	07:57:00	17:14:00	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7073c	07:56:00	17:13:00	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7073d	08:20:00	16:35:00	LATE_AND_EARLY	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7073e	07:49:00	17:16:00	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7073f	08:20:00	17:15:00	LATE	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70740	08:22:00	17:17:00	LATE	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70741	08:19:00	17:14:00	LATE	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70742	07:53:00	17:10:00	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70743	07:54:00	17:21:00	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70744	07:52:00	16:41:00	EARLY	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70745	07:50:00	\N	MISSING	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70746	07:52:00	16:39:00	EARLY	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70747	07:51:00	17:18:00	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70748	07:51:00	17:08:00	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70749	07:50:00	17:17:00	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7074a	07:48:00	17:15:00	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7074b	07:57:00	17:14:00	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7074c	08:20:00	16:35:00	LATE_AND_EARLY	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7074d	07:50:00	17:17:00	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7074e	08:19:00	17:14:00	LATE	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7074f	08:23:00	17:18:00	LATE	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70750	08:20:00	17:15:00	LATE	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70751	07:52:00	17:09:00	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70752	07:55:00	17:22:00	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70753	07:52:00	16:40:00	EARLY	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70754	07:50:00	\N	MISSING	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70755	07:52:00	16:40:00	EARLY	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70756	07:52:00	17:19:00	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70757	07:50:00	17:07:00	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70758	07:51:00	17:18:00	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70759	07:49:00	17:16:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7075a	08:20:00	16:35:00	LATE_AND_EARLY	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7075b	07:50:00	17:17:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7075c	07:50:00	\N	MISSING	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7075d	07:56:00	17:23:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7075e	07:52:00	17:09:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7075f	07:49:00	17:06:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70760	07:51:00	17:08:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70761	07:56:00	17:23:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70762	07:52:00	17:09:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70763	07:54:00	17:21:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70764	07:54:00	17:11:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70765	07:50:00	\N	MISSING	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70766	07:49:00	17:06:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70767	07:50:00	\N	MISSING	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70768	07:50:00	17:17:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70769	08:20:00	16:35:00	LATE_AND_EARLY	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7076a	07:51:00	17:18:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7076b	07:50:00	\N	MISSING	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7076c	07:55:00	17:22:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7076d	07:53:00	17:10:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7076e	07:50:00	17:07:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7076f	07:50:00	17:07:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70770	07:57:00	17:24:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70771	07:51:00	17:08:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70772	07:55:00	17:22:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70773	07:55:00	17:12:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70774	\N	\N	BUSINESS_TRIP	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70775	07:48:00	17:05:00	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70776	07:50:00	\N	MISSING	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70777	07:51:00	17:18:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70778	07:50:00	\N	MISSING	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70779	07:52:00	17:19:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7077a	07:50:00	\N	MISSING	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7077b	07:54:00	17:21:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7077c	07:54:00	17:11:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7077d	07:51:00	17:08:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7077e	07:49:00	17:06:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead7077f	07:48:00	17:05:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70780	07:50:00	17:07:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70781	07:56:00	17:23:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead70782	07:56:00	17:13:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80783	\N	\N	BUSINESS_TRIP	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80784	07:57:00	17:24:00	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80785	\N	\N	BUSINESS_TRIP	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80786	07:52:00	17:19:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80787	07:50:00	\N	MISSING	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80788	07:53:00	17:20:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80789	\N	\N	BUSINESS_TRIP	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8078a	07:53:00	17:20:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8078b	07:55:00	17:12:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8078c	07:52:00	17:09:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8078d	07:48:00	17:05:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8078e	07:49:00	17:06:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8078f	07:49:00	17:06:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80790	07:57:00	17:24:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80791	07:57:00	17:14:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80792	\N	\N	UNEXCUSED_ABSENCE	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80793	07:56:00	17:23:00	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80794	\N	\N	BUSINESS_TRIP	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80795	07:53:00	17:20:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80796	07:50:00	\N	MISSING	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80797	07:54:00	17:21:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80798	\N	\N	BUSINESS_TRIP	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead80799	07:52:00	17:19:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8079a	07:56:00	17:13:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8079b	07:53:00	17:10:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8079c	07:57:00	17:24:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8079d	07:50:00	17:07:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8079e	07:48:00	17:05:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead8079f	07:48:00	17:05:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a0	07:48:00	17:15:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a1	\N	\N	UNEXCUSED_ABSENCE	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a2	07:55:00	17:22:00	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a3	\N	\N	UNEXCUSED_ABSENCE	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a4	08:18:00	17:13:00	LATE	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a5	\N	\N	BUSINESS_TRIP	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a6	07:57:00	17:24:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a7	07:48:00	17:05:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a8	07:49:00	17:16:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807a9	07:49:00	17:16:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807aa	07:56:00	17:13:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807ab	07:54:00	17:21:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807ac	07:53:00	17:10:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807ad	07:55:00	17:22:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807ae	\N	\N	PAID_LEAVE	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807af	07:51:00	17:18:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b0	07:50:00	17:07:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b1	07:52:00	17:19:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b2	07:49:00	17:06:00	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b3	08:19:00	17:14:00	LATE	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b4	\N	\N	PAID_LEAVE	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b5	07:48:00	17:05:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b6	07:49:00	17:06:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b7	07:48:00	17:15:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b8	07:50:00	17:17:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807b9	07:57:00	17:14:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807ba	07:53:00	17:20:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807bb	07:54:00	17:11:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807bc	07:54:00	17:21:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807bd	\N	\N	PAID_LEAVE	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807be	\N	\N	PAID_LEAVE	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807bf	07:51:00	17:08:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c0	07:51:00	17:18:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c1	07:50:00	17:07:00	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c2	07:49:00	17:06:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c3	07:48:00	17:05:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c4	07:50:00	17:07:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c5	07:51:00	17:08:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c6	07:56:00	17:13:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c7	07:52:00	17:19:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c8	07:49:00	17:16:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807c9	07:50:00	\N	MISSING	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807ca	07:56:00	17:13:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807cb	07:52:00	17:19:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807cc	07:54:00	17:11:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807cd	07:54:00	17:21:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807ce	07:53:00	17:10:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807cf	07:49:00	17:16:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d0	07:52:00	17:09:00	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d1	07:50:00	17:07:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d2	07:49:00	17:06:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d3	07:51:00	17:08:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d4	07:52:00	17:09:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d5	07:55:00	17:12:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d6	07:53:00	17:20:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d7	07:50:00	17:17:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d8	07:50:00	\N	MISSING	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807d9	07:57:00	17:14:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead807da	07:51:00	17:18:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907db	07:55:00	17:12:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907dc	07:55:00	17:22:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907dd	07:54:00	17:11:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907de	07:48:00	17:15:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907df	07:53:00	17:10:00	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e0	07:51:00	17:08:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e1	07:50:00	17:07:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e2	07:52:00	17:09:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e3	07:53:00	17:10:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e4	\N	\N	PAID_LEAVE	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e5	07:54:00	17:21:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e6	07:51:00	17:18:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e7	08:20:00	16:35:00	LATE_AND_EARLY	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e8	07:48:00	17:15:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907e9	07:50:00	17:17:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907ea	07:56:00	17:13:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907eb	07:56:00	17:23:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907ec	07:55:00	17:12:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907ed	07:57:00	17:14:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907ee	07:54:00	17:11:00	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907ef	07:54:00	17:11:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f0	07:53:00	17:10:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f1	07:55:00	17:12:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f2	07:56:00	17:13:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f3	07:51:00	17:08:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f4	07:57:00	17:24:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f5	\N	\N	PAID_LEAVE	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f6	07:52:00	16:43:00	EARLY	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f7	07:51:00	17:18:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f8	07:57:00	17:14:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907f9	07:49:00	17:16:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907fa	07:49:00	17:06:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907fb	07:48:00	17:15:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907fc	07:54:00	17:11:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907fd	07:57:00	17:14:00	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907fe	07:55:00	17:12:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead907ff	07:54:00	17:11:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead90800	07:56:00	17:13:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead90801	07:57:00	17:14:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924ead90802	07:50:00	17:07:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0803	07:48:00	17:05:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0804	07:55:00	17:22:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0805	07:52:00	16:42:00	EARLY	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0806	07:52:00	17:19:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0807	07:56:00	17:13:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0808	07:50:00	17:17:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0809	07:50:00	17:07:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada080a	07:49:00	17:16:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada080b	07:53:00	17:10:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada080c	07:48:00	17:15:00	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada080d	07:56:00	17:13:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada080e	07:55:00	17:12:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada080f	07:57:00	17:14:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0810	07:48:00	17:15:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0811	07:49:00	17:06:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0812	07:49:00	17:06:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0813	07:56:00	17:23:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0814	07:52:00	16:41:00	EARLY	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0815	07:53:00	17:20:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0816	07:55:00	17:12:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0817	07:51:00	17:18:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0818	07:51:00	17:08:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0819	07:50:00	17:17:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada081a	07:52:00	17:09:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada081b	07:49:00	17:16:00	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada081c	07:57:00	17:14:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada081d	07:56:00	17:13:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada081e	07:48:00	17:15:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada081f	07:49:00	17:16:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0820	07:48:00	17:05:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0821	07:50:00	17:07:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0822	07:57:00	17:24:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0823	07:52:00	16:40:00	EARLY	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0824	08:16:00	17:11:00	LATE	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0825	07:54:00	17:11:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0826	07:52:00	17:19:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0827	07:52:00	17:09:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0828	07:51:00	17:18:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0829	07:51:00	17:08:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada082a	07:50:00	17:17:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada082b	07:48:00	17:15:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada082c	07:57:00	17:14:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada082d	07:49:00	17:16:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada082e	07:50:00	17:17:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada082f	07:57:00	17:24:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0830	07:51:00	17:08:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0831	07:48:00	17:05:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0832	07:52:00	16:39:00	EARLY	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0833	08:17:00	17:12:00	LATE	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0834	07:53:00	17:10:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0835	07:53:00	17:20:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0836	07:53:00	17:10:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0837	07:52:00	17:19:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0838	07:50:00	17:07:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0839	07:51:00	17:18:00	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada083a	07:52:00	17:19:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada083b	07:51:00	17:18:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada083c	07:53:00	17:20:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada083d	07:54:00	17:21:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada083e	07:50:00	\N	MISSING	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada083f	07:55:00	17:12:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0840	07:52:00	17:09:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0841	07:48:00	17:05:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0842	07:49:00	17:06:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0843	07:49:00	17:06:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0844	08:19:00	17:14:00	LATE	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0845	07:57:00	17:14:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0846	07:56:00	17:23:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0847	08:18:00	17:13:00	LATE	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0848	07:55:00	17:22:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada0849	07:53:00	17:20:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada084a	07:52:00	17:19:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada084b	08:16:00	17:11:00	LATE	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eada084c	07:55:00	17:22:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb084d	07:50:00	\N	MISSING	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb084e	07:56:00	17:13:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb084f	07:53:00	17:10:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0850	07:57:00	17:24:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0851	07:50:00	17:07:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0852	07:48:00	17:05:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0853	08:20:00	17:15:00	LATE	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0854	07:48:00	17:15:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0855	07:57:00	17:24:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0856	08:17:00	17:12:00	LATE	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0857	07:56:00	17:23:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0858	07:54:00	17:21:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0859	07:53:00	17:20:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb085a	08:17:00	17:12:00	LATE	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb085b	07:56:00	17:23:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb085c	07:50:00	\N	MISSING	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb085d	07:57:00	17:14:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb085e	07:54:00	17:11:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb085f	07:56:00	17:23:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0860	07:51:00	17:08:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0861	\N	\N	UNEXCUSED_ABSENCE	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0862	08:21:00	17:16:00	LATE	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0863	07:49:00	17:16:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0864	07:48:00	17:05:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0865	08:16:00	17:11:00	LATE	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0866	07:57:00	17:24:00	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0867	07:55:00	17:22:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0868	07:54:00	17:21:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0869	08:18:00	17:13:00	LATE	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb086a	07:57:00	17:24:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb086b	07:50:00	\N	MISSING	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb086c	07:48:00	17:15:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb086d	07:55:00	17:12:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb086e	07:55:00	17:22:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb086f	07:52:00	17:09:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0870	\N	\N	UNEXCUSED_ABSENCE	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0871	08:22:00	17:17:00	LATE	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0872	07:50:00	17:17:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0873	07:49:00	17:06:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0874	07:53:00	17:20:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0875	07:48:00	17:05:00	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0876	07:56:00	17:23:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0877	07:55:00	17:22:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0878	08:19:00	17:14:00	LATE	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0879	07:48:00	17:05:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb087a	08:20:00	16:35:00	LATE_AND_EARLY	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb087b	07:49:00	17:16:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb087c	07:56:00	17:13:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb087d	07:54:00	17:21:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb087e	07:53:00	17:10:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb087f	\N	\N	BUSINESS_TRIP	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0880	08:23:00	17:18:00	LATE	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0881	07:51:00	17:18:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0882	07:50:00	17:07:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0883	07:52:00	17:19:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0884	07:49:00	17:06:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0885	07:49:00	17:06:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0886	07:48:00	17:05:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0887	08:22:00	17:17:00	LATE	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0888	07:51:00	17:08:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0889	07:52:00	16:43:00	EARLY	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb088a	07:52:00	17:19:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb088b	07:49:00	17:16:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb088c	07:51:00	17:18:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb088d	07:56:00	17:13:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb088e	07:50:00	\N	MISSING	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb088f	07:52:00	16:41:00	EARLY	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0890	08:16:00	17:11:00	LATE	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0891	07:53:00	17:10:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0892	07:49:00	17:16:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0893	07:52:00	17:09:00	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0894	07:51:00	17:08:00	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0895	08:22:00	17:17:00	LATE	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0896	07:52:00	17:09:00	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0897	07:52:00	16:40:00	EARLY	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0898	07:54:00	17:11:00	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb0899	\N	\N	BUSINESS_TRIP	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb089a	07:50:00	\N	MISSING	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb089b	07:49:00	17:16:00	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb089c	07:48:00	17:15:00	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb089d	07:50:00	17:17:00	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb089e	07:56:00	17:13:00	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb089f	\N	\N	UNEXCUSED_ABSENCE	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a0	07:52:00	16:42:00	EARLY	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a1	07:57:00	17:14:00	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a2	07:52:00	16:41:00	EARLY	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a3	07:50:00	17:07:00	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a4	08:21:00	17:16:00	LATE	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a5	07:51:00	17:08:00	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a6	07:52:00	16:39:00	EARLY	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a7	07:55:00	17:12:00	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a8	07:50:00	\N	MISSING	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08a9	07:50:00	\N	MISSING	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08aa	07:50:00	17:17:00	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08ab	07:57:00	17:14:00	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08ac	07:51:00	17:18:00	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08ad	07:55:00	17:12:00	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08ae	\N	\N	BUSINESS_TRIP	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08af	07:52:00	16:41:00	EARLY	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08b0	07:48:00	17:15:00	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08b1	07:52:00	16:40:00	EARLY	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadb08b2	07:51:00	17:08:00	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08b3	08:22:00	17:17:00	LATE	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08b4	07:52:00	17:09:00	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08b5	07:52:00	16:40:00	EARLY	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08b6	07:54:00	17:11:00	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08b7	\N	\N	BUSINESS_TRIP	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08b8	07:50:00	\N	MISSING	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08b9	07:49:00	17:16:00	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08ba	07:48:00	17:15:00	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08bb	07:50:00	17:17:00	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08bc	07:56:00	17:13:00	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08bd	\N	\N	UNEXCUSED_ABSENCE	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08be	07:52:00	16:42:00	EARLY	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08bf	07:57:00	17:14:00	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c0	07:52:00	16:41:00	EARLY	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c1	07:52:00	17:09:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c2	08:23:00	17:18:00	LATE	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c3	07:53:00	17:10:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c4	07:52:00	16:41:00	EARLY	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c5	07:53:00	17:10:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c6	\N	\N	BUSINESS_TRIP	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c7	07:50:00	\N	MISSING	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c8	07:48:00	17:15:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08c9	07:49:00	17:16:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08ca	07:49:00	17:16:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08cb	07:57:00	17:14:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08cc	\N	\N	UNEXCUSED_ABSENCE	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08cd	07:52:00	16:43:00	EARLY	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08ce	07:56:00	17:13:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08cf	07:52:00	16:42:00	EARLY	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d0	07:55:00	17:12:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d1	07:52:00	16:41:00	EARLY	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d2	07:56:00	17:13:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d3	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d4	07:50:00	17:07:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d5	07:48:00	17:05:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d6	\N	\N	BUSINESS_TRIP	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d7	07:55:00	17:12:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d8	07:52:00	17:19:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08d9	07:56:00	17:13:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08da	07:50:00	17:17:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08db	07:50:00	17:07:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08dc	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08dd	07:53:00	17:10:00	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08de	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08df	07:56:00	17:13:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e0	07:52:00	16:42:00	EARLY	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e1	07:57:00	17:14:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e2	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e3	07:49:00	17:06:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e4	07:49:00	17:06:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e5	\N	\N	UNEXCUSED_ABSENCE	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e6	07:54:00	17:11:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e7	07:53:00	17:20:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e8	07:55:00	17:12:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08e9	07:51:00	17:18:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08ea	07:51:00	17:08:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08eb	07:50:00	\N	MISSING	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08ec	07:52:00	17:09:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08ed	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08ee	07:57:00	17:14:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08ef	07:52:00	16:43:00	EARLY	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f0	07:48:00	17:15:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f1	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f2	07:48:00	17:05:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f3	07:50:00	17:07:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f4	\N	\N	UNEXCUSED_ABSENCE	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f5	07:53:00	17:10:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f6	07:54:00	17:21:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f7	07:54:00	17:11:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f8	07:52:00	17:19:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08f9	07:52:00	17:09:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08fa	07:50:00	\N	MISSING	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08fb	07:51:00	17:08:00	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-8924eadc08fc	07:50:00	\N	MISSING	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca08fd	07:48:00	17:15:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca08fe	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca08ff	07:49:00	17:16:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0900	07:50:00	\N	MISSING	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0901	07:57:00	17:24:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0902	07:51:00	17:08:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0903	07:48:00	17:05:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0904	07:52:00	17:09:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0905	07:55:00	17:22:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0906	07:53:00	17:10:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0907	07:53:00	17:20:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0908	07:53:00	17:10:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0909	07:50:00	\N	MISSING	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca090a	07:50:00	17:07:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca090b	07:50:00	\N	MISSING	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca090c	07:50:00	\N	MISSING	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca090d	07:49:00	17:16:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca090e	07:51:00	17:18:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca090f	07:52:00	17:19:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0910	07:55:00	17:22:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0911	07:53:00	17:10:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0912	07:50:00	17:07:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0913	07:50:00	17:07:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0914	07:57:00	17:24:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0915	07:51:00	17:08:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fca0916	07:55:00	17:22:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0917	07:55:00	17:12:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0918	07:54:00	17:21:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0919	07:48:00	17:05:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb091a	07:53:00	17:20:00	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb091b	07:50:00	\N	MISSING	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb091c	07:52:00	17:19:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb091d	07:54:00	17:21:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb091e	07:55:00	17:22:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb091f	07:52:00	17:19:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0920	07:56:00	17:13:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0921	07:53:00	17:10:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0922	\N	\N	UNEXCUSED_ABSENCE	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0923	07:50:00	17:07:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0924	07:48:00	17:05:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0925	07:48:00	17:05:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0926	07:48:00	17:15:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0927	07:57:00	17:24:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0928	07:55:00	17:22:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0929	07:56:00	17:23:00	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb092a	\N	\N	BUSINESS_TRIP	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb092b	07:53:00	17:20:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb092c	07:55:00	17:22:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb092d	07:56:00	17:23:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb092e	07:51:00	17:18:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb092f	07:57:00	17:14:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0930	07:54:00	17:11:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0931	\N	\N	UNEXCUSED_ABSENCE	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0932	07:51:00	17:08:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0933	07:57:00	17:24:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0934	07:49:00	17:06:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0935	07:49:00	17:16:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0936	07:48:00	17:05:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0937	07:54:00	17:21:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0938	07:57:00	17:24:00	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0939	\N	\N	BUSINESS_TRIP	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb093a	07:54:00	17:21:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb093b	07:56:00	17:23:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb093c	07:57:00	17:24:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb093d	07:50:00	17:17:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb093e	07:48:00	17:15:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb093f	07:55:00	17:12:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0940	\N	\N	BUSINESS_TRIP	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0941	07:52:00	17:09:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0942	07:56:00	17:23:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0943	07:50:00	17:07:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0944	07:50:00	17:17:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0945	07:49:00	17:06:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0946	07:53:00	17:20:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0947	07:48:00	17:05:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0948	\N	\N	UNEXCUSED_ABSENCE	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0949	07:55:00	17:22:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb094a	07:57:00	17:24:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb094b	07:48:00	17:05:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb094c	07:49:00	17:16:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb094d	07:49:00	17:16:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb094e	07:56:00	17:13:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb094f	\N	\N	BUSINESS_TRIP	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0950	07:53:00	17:10:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0951	07:55:00	17:22:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0952	07:51:00	17:08:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0953	07:51:00	17:18:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0954	07:50:00	17:07:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0955	07:52:00	17:19:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0956	07:49:00	17:06:00	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0957	\N	\N	UNEXCUSED_ABSENCE	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0958	07:56:00	17:23:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0959	07:48:00	17:05:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb095a	07:49:00	17:06:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb095b	07:48:00	17:15:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb095c	07:50:00	17:17:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb095d	07:57:00	17:14:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb095e	07:50:00	\N	MISSING	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb095f	07:54:00	17:11:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0960	07:54:00	17:21:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0961	07:52:00	17:09:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0962	07:52:00	17:19:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcb0963	07:51:00	17:08:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0964	07:51:00	17:18:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0965	07:50:00	17:07:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0966	07:51:00	17:08:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0967	07:50:00	17:07:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0968	07:52:00	17:09:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0969	07:53:00	17:10:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc096a	07:54:00	17:11:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc096b	07:54:00	17:21:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc096c	07:51:00	17:18:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc096d	07:49:00	17:16:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc096e	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc096f	07:50:00	17:17:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0970	07:56:00	17:13:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0971	07:56:00	17:23:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0972	07:55:00	17:12:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0973	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0974	07:54:00	17:11:00	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0975	07:52:00	17:09:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0976	07:51:00	17:08:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0977	07:53:00	17:10:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0978	07:54:00	17:11:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0979	07:53:00	17:10:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc097a	07:55:00	17:22:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc097b	07:52:00	17:19:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc097c	07:48:00	17:15:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc097d	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc097e	07:49:00	17:16:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc097f	07:57:00	17:14:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0980	07:57:00	17:24:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0981	07:56:00	17:13:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0982	07:52:00	16:43:00	EARLY	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0983	07:55:00	17:12:00	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0984	07:53:00	17:10:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0985	07:52:00	17:09:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0986	07:54:00	17:11:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0987	07:55:00	17:12:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0988	07:52:00	17:09:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0989	07:56:00	17:23:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc098a	07:53:00	17:20:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc098b	07:57:00	17:14:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc098c	07:50:00	\N	MISSING	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc098d	07:48:00	17:15:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc098e	07:48:00	17:15:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc098f	07:48:00	17:05:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0990	07:57:00	17:14:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0991	07:52:00	16:42:00	EARLY	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0992	07:56:00	17:13:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0993	07:54:00	17:11:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0994	07:53:00	17:10:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0995	07:55:00	17:12:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0996	07:56:00	17:13:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0997	07:51:00	17:08:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0998	07:57:00	17:24:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc0999	07:54:00	17:21:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc099a	07:56:00	17:13:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc099b	07:50:00	\N	MISSING	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc099c	07:57:00	17:14:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc099d	07:49:00	17:16:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc099e	07:49:00	17:06:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc099f	07:48:00	17:15:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a0	07:52:00	16:41:00	EARLY	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a1	07:57:00	17:14:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a2	07:55:00	17:12:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a3	07:54:00	17:11:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a4	07:56:00	17:13:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a5	07:57:00	17:14:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a6	07:50:00	17:07:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a7	07:48:00	17:05:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a8	07:55:00	17:22:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09a9	07:55:00	17:12:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09aa	07:50:00	\N	MISSING	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09ab	07:56:00	17:13:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09ac	07:50:00	17:17:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09ad	07:50:00	17:07:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09ae	07:49:00	17:16:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09af	07:52:00	16:40:00	EARLY	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b0	07:48:00	17:15:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b1	07:48:00	17:15:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b2	07:57:00	17:14:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b3	07:49:00	17:16:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b4	07:50:00	17:17:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b5	\N	\N	UNEXCUSED_ABSENCE	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b6	07:51:00	17:08:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b7	07:48:00	17:05:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b8	07:52:00	17:09:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09b9	\N	\N	BUSINESS_TRIP	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09ba	07:53:00	17:10:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09bb	07:53:00	17:20:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09bc	07:53:00	17:10:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09bd	07:52:00	17:19:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09be	08:22:00	17:17:00	LATE	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09bf	07:51:00	17:18:00	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c0	07:49:00	17:16:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c1	07:48:00	17:15:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c2	07:50:00	17:17:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c3	07:51:00	17:18:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c4	\N	\N	UNEXCUSED_ABSENCE	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c5	07:52:00	17:09:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c6	07:49:00	17:06:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c7	07:51:00	17:08:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c8	\N	\N	UNEXCUSED_ABSENCE	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09c9	07:52:00	17:09:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09ca	08:16:00	17:11:00	LATE	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09cb	07:54:00	17:11:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09cc	07:53:00	17:20:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09cd	08:21:00	17:16:00	LATE	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcc09ce	07:52:00	17:19:00	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09cf	07:50:00	17:17:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d0	07:49:00	17:16:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d1	07:51:00	17:18:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d2	07:52:00	17:19:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d3	\N	\N	BUSINESS_TRIP	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d4	07:53:00	17:10:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d5	07:50:00	17:07:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d6	07:50:00	17:07:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d7	\N	\N	UNEXCUSED_ABSENCE	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d8	07:51:00	17:08:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09d9	08:17:00	17:12:00	LATE	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09da	07:55:00	17:12:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09db	07:54:00	17:21:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09dc	08:20:00	17:15:00	LATE	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09dd	07:53:00	17:20:00	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09de	07:52:00	17:19:00	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09df	07:51:00	17:18:00	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e0	07:50:00	\N	MISSING	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e1	08:16:00	17:11:00	LATE	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e2	07:53:00	17:20:00	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e3	07:52:00	16:42:00	EARLY	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e4	07:52:00	16:39:00	EARLY	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e5	07:48:00	17:05:00	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e6	07:49:00	17:06:00	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e7	08:21:00	17:16:00	LATE	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e8	\N	\N	UNEXCUSED_ABSENCE	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09e9	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09ea	08:18:00	17:13:00	LATE	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09eb	07:56:00	17:23:00	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09ec	08:17:00	17:12:00	LATE	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09ed	07:53:00	17:20:00	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09ee	07:52:00	17:19:00	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09ef	\N	\N	BUSINESS_TRIP	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f0	08:17:00	17:12:00	LATE	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f1	07:52:00	17:19:00	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f2	07:52:00	16:43:00	EARLY	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f3	07:52:00	16:40:00	EARLY	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f4	07:57:00	17:24:00	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f5	07:50:00	17:07:00	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f6	08:20:00	17:15:00	LATE	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f7	07:48:00	17:05:00	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f8	08:20:00	16:35:00	LATE_AND_EARLY	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09f9	08:19:00	17:14:00	LATE	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09fa	07:55:00	17:22:00	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09fb	08:18:00	17:13:00	LATE	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09fc	07:53:00	17:20:00	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09fd	07:52:00	17:19:00	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09fe	\N	\N	BUSINESS_TRIP	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd09ff	08:17:00	17:12:00	LATE	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a00	07:52:00	17:19:00	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a01	07:52:00	16:43:00	EARLY	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a02	07:52:00	16:40:00	EARLY	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a03	07:57:00	17:24:00	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a04	07:50:00	17:07:00	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a05	08:20:00	17:15:00	LATE	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a06	07:48:00	17:05:00	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a07	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a08	08:19:00	17:14:00	LATE	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a09	07:55:00	17:22:00	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a0a	08:18:00	17:13:00	LATE	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a0b	07:54:00	17:21:00	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a0c	07:53:00	17:20:00	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a0d	\N	\N	BUSINESS_TRIP	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a0e	08:18:00	17:13:00	LATE	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a0f	07:51:00	17:18:00	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a10	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a11	07:52:00	16:41:00	EARLY	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a12	07:56:00	17:23:00	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a13	07:51:00	17:08:00	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a14	08:19:00	17:14:00	LATE	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a15	07:49:00	17:06:00	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a16	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a17	08:20:00	17:15:00	LATE	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a18	07:54:00	17:21:00	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a19	08:19:00	17:14:00	LATE	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a1a	07:55:00	17:22:00	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a1b	08:16:00	17:11:00	LATE	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a1c	\N	\N	UNEXCUSED_ABSENCE	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a1d	08:19:00	17:14:00	LATE	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a1e	07:50:00	17:17:00	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a1f	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a20	07:52:00	16:42:00	EARLY	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a21	07:55:00	17:22:00	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a22	07:52:00	17:09:00	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a23	08:18:00	17:13:00	LATE	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a24	07:50:00	17:07:00	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a25	07:50:00	\N	MISSING	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a26	08:21:00	17:16:00	LATE	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a27	07:53:00	17:20:00	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a28	08:20:00	17:15:00	LATE	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a29	07:56:00	17:23:00	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a2a	08:17:00	17:12:00	LATE	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a2b	\N	\N	UNEXCUSED_ABSENCE	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a2c	08:20:00	17:15:00	LATE	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a2d	07:49:00	17:16:00	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a2e	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a2f	07:52:00	16:43:00	EARLY	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a30	07:54:00	17:21:00	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a31	07:53:00	17:10:00	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a32	08:17:00	17:12:00	LATE	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a33	07:51:00	17:08:00	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a34	07:50:00	\N	MISSING	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a35	08:22:00	17:17:00	LATE	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a36	07:52:00	17:19:00	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a37	08:21:00	17:16:00	LATE	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcd0a38	07:57:00	17:24:00	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a39	08:18:00	17:13:00	LATE	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a3a	07:48:00	17:05:00	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a3b	08:21:00	17:16:00	LATE	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a3c	07:48:00	17:15:00	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a3d	07:50:00	\N	MISSING	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a3e	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a3f	07:53:00	17:20:00	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a40	07:54:00	17:11:00	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a41	08:16:00	17:11:00	LATE	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a42	07:52:00	17:09:00	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a43	07:50:00	\N	MISSING	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a44	08:23:00	17:18:00	LATE	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a45	07:51:00	17:18:00	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a46	08:22:00	17:17:00	LATE	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a47	08:23:00	17:18:00	LATE	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a48	07:50:00	17:07:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a49	07:52:00	17:09:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a4a	07:53:00	17:10:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a4b	07:54:00	17:11:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a4c	07:54:00	17:21:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a4d	07:51:00	17:18:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a4e	07:49:00	17:16:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a4f	07:48:00	17:15:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a50	07:50:00	17:17:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a51	07:56:00	17:13:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a52	07:56:00	17:23:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a53	\N	\N	PAID_LEAVE	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a54	07:57:00	17:14:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a55	07:54:00	17:11:00	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a56	07:52:00	16:39:00	EARLY	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a57	07:51:00	17:08:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a58	07:53:00	17:10:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a59	\N	\N	PAID_LEAVE	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a5a	07:53:00	17:10:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a5b	07:55:00	17:22:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a5c	07:52:00	17:19:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a5d	07:48:00	17:15:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a5e	07:49:00	17:16:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a5f	07:49:00	17:16:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a60	07:57:00	17:14:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a61	07:57:00	17:24:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a62	\N	\N	PAID_LEAVE	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a63	\N	\N	PAID_LEAVE	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a64	07:55:00	17:12:00	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a65	07:52:00	16:40:00	EARLY	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a66	07:52:00	17:09:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a67	07:54:00	17:11:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a68	07:55:00	17:12:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a69	07:52:00	17:09:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a6a	07:56:00	17:23:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a6b	07:53:00	17:20:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a6c	07:57:00	17:14:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a6d	07:50:00	17:17:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a6e	07:48:00	17:15:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a6f	07:48:00	17:15:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a70	07:48:00	17:05:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a71	07:57:00	17:14:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a72	07:55:00	17:12:00	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a73	\N	\N	PAID_LEAVE	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a74	07:52:00	16:41:00	EARLY	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a75	07:53:00	17:10:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a76	07:55:00	17:12:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a77	07:56:00	17:13:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a78	07:51:00	17:08:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a79	\N	\N	PAID_LEAVE	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a7a	07:54:00	17:21:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a7b	07:56:00	17:13:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a7c	07:51:00	17:18:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a7d	07:57:00	17:14:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a7e	07:49:00	17:16:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a7f	07:49:00	17:06:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a80	07:48:00	17:15:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a81	07:54:00	17:11:00	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a82	\N	\N	PAID_LEAVE	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a83	07:52:00	16:42:00	EARLY	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a84	07:54:00	17:11:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a85	07:56:00	17:13:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a86	07:57:00	17:14:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a87	07:50:00	17:07:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a88	07:48:00	17:05:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a89	07:55:00	17:22:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a8a	07:55:00	17:12:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a8b	07:52:00	17:19:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a8c	07:56:00	17:13:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a8d	07:50:00	17:17:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a8e	07:50:00	17:07:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a8f	07:49:00	17:16:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a90	07:53:00	17:10:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fce0a91	07:48:00	17:15:00	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a92	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a93	07:57:00	17:14:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a94	07:49:00	17:16:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a95	07:50:00	17:17:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a96	07:57:00	17:24:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a97	07:51:00	17:08:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a98	07:48:00	17:05:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a99	07:52:00	17:09:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a9a	\N	\N	PAID_LEAVE	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a9b	\N	\N	PAID_LEAVE	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a9c	07:53:00	17:20:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a9d	07:53:00	17:10:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a9e	07:52:00	17:19:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0a9f	07:50:00	17:07:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa0	07:51:00	17:18:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa1	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa2	07:48:00	17:15:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa3	07:50:00	17:17:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa4	07:51:00	17:18:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa5	07:56:00	17:23:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa6	07:52:00	17:09:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa7	07:49:00	17:06:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa8	07:51:00	17:08:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aa9	07:56:00	17:23:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aaa	07:52:00	17:09:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aab	07:54:00	17:21:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aac	07:54:00	17:11:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aad	07:53:00	17:20:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aae	07:49:00	17:06:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aaf	07:52:00	17:19:00	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab0	07:50:00	\N	MISSING	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab1	07:49:00	17:16:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab2	07:51:00	17:18:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab3	07:52:00	17:19:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab4	07:55:00	17:22:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab5	07:53:00	17:10:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab6	07:50:00	17:07:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab7	07:50:00	17:07:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab8	07:57:00	17:24:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ab9	07:51:00	17:08:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aba	07:55:00	17:22:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0abb	07:55:00	17:12:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0abc	07:54:00	17:21:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0abd	07:48:00	17:05:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0abe	07:53:00	17:20:00	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0abf	07:52:00	17:19:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac0	07:51:00	17:18:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac1	07:53:00	17:20:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac2	07:54:00	17:21:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac3	07:53:00	17:20:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac4	07:55:00	17:12:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac5	07:52:00	17:09:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac6	08:20:00	17:15:00	LATE	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac7	08:21:00	17:16:00	LATE	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac8	07:49:00	17:06:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ac9	07:57:00	17:24:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aca	07:57:00	17:14:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0acb	07:56:00	17:23:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0acc	\N	\N	UNEXCUSED_ABSENCE	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0acd	07:55:00	17:22:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ace	07:53:00	17:20:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0acf	07:52:00	17:19:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad0	07:54:00	17:21:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad1	07:55:00	17:22:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad2	07:52:00	17:19:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad3	07:56:00	17:13:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad4	07:53:00	17:10:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad5	08:19:00	17:14:00	LATE	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad6	08:22:00	17:17:00	LATE	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad7	07:48:00	17:05:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad8	07:48:00	17:05:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ad9	07:48:00	17:15:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ada	07:57:00	17:24:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0adb	\N	\N	BUSINESS_TRIP	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0adc	07:56:00	17:23:00	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0add	07:56:00	17:23:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ade	07:55:00	17:22:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0adf	07:57:00	17:24:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae0	07:48:00	17:05:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae1	07:49:00	17:16:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae2	07:49:00	17:16:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae3	07:56:00	17:13:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae4	08:16:00	17:11:00	LATE	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae5	07:52:00	16:40:00	EARLY	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae6	07:55:00	17:22:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae7	07:51:00	17:08:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae8	07:51:00	17:18:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0ae9	07:50:00	17:07:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aea	07:50:00	\N	MISSING	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aeb	07:49:00	17:06:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aec	07:57:00	17:24:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aed	07:56:00	17:23:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aee	07:48:00	17:05:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0aef	07:49:00	17:06:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0af0	07:48:00	17:15:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0af1	07:50:00	17:17:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fcf0af2	07:57:00	17:14:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fd00af3	07:53:00	17:20:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fd00af4	07:52:00	16:41:00	EARLY	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fd00af5	07:54:00	17:21:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fd00af6	07:52:00	17:09:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fd00af7	07:52:00	17:19:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fd00af8	07:51:00	17:08:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fd00af9	07:50:00	\N	MISSING	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-89250fd00afa	07:50:00	17:07:00	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ed0afb	07:48:00	17:05:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ed0afc	07:57:00	17:24:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0afd	07:49:00	17:06:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0afe	07:50:00	17:07:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0aff	07:57:00	17:14:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b00	07:51:00	17:18:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b01	07:48:00	17:15:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b02	07:52:00	17:19:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b03	07:52:00	16:42:00	EARLY	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b04	07:53:00	17:20:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b05	07:53:00	17:10:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b06	07:53:00	17:20:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b07	07:52:00	17:09:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b08	07:50:00	\N	MISSING	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b09	07:51:00	17:08:00	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b0a	07:49:00	17:06:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b0b	07:48:00	17:05:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b0c	07:50:00	17:07:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b0d	07:51:00	17:08:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b0e	07:56:00	17:13:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b0f	07:52:00	17:19:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b10	07:49:00	17:16:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b11	07:51:00	17:18:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b12	07:52:00	16:43:00	EARLY	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b13	07:52:00	17:19:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b14	07:54:00	17:11:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b15	07:54:00	17:21:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b16	07:53:00	17:10:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b17	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b18	07:52:00	17:09:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b19	07:50:00	17:07:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b1a	07:49:00	17:06:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b1b	07:51:00	17:08:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b1c	07:52:00	17:09:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b1d	07:55:00	17:12:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b1e	07:53:00	17:20:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b1f	07:50:00	17:17:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b20	07:50:00	17:17:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b21	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b22	07:51:00	17:18:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b23	07:55:00	17:12:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b24	07:55:00	17:22:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b25	07:54:00	17:11:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b26	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b27	07:53:00	17:10:00	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b28	07:54:00	17:11:00	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b29	07:53:00	17:10:00	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b2a	07:52:00	16:42:00	EARLY	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b2b	07:56:00	17:13:00	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b2c	08:23:00	17:18:00	LATE	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b2d	08:19:00	17:14:00	LATE	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b2e	08:16:00	17:11:00	LATE	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b2f	07:56:00	17:13:00	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b30	07:51:00	17:18:00	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b31	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b32	08:20:00	16:35:00	LATE_AND_EARLY	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b33	08:21:00	17:16:00	LATE	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b34	07:48:00	17:15:00	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b35	07:54:00	17:11:00	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9fea941-a089-1454-81a0-892515ee0b36	07:57:00	17:14:00	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
\.


--
-- Data for Name: comment_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comment_reactions (reaction_id, created_at, reaction, updated_at, comment_id, user_id) FROM stdin;
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments (comment_id, created_at, media_url, reaction_count, reply_count, text_content, updated_at, parent_comment_id, interactable_id, user_id) FROM stdin;
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departments (department_id, name) FROM stdin;
0190abcd-2345-7def-89ab-cdef01234568	Sales
0190abcd-3456-7def-89ab-cdef01234569	Marketing & Communication
0190abcd-4567-7def-89ab-cdef0123456a	Human Resources
0190abcd-5678-7def-89ab-cdef0123456b	Finance & Accounting
0190abcd-6789-7def-89ab-cdef0123456c	Customer Support
0190abcd-7890-7def-89ab-cdef0123456d	Executive Leadership
0190abcd-1234-7def-89ab-cdef01234567	IT
\.


--
-- Data for Name: hashtags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hashtags (hashtag_id, created_at, hashtag_name) FROM stdin;
\.


--
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.holidays (holiday_id, date, description) FROM stdin;
0c7580f0-3677-42d6-9a7e-f23e48587503	2026-01-01	New Year's Day (T?t Duong l?ch)
e23dd17a-956f-4c6a-a167-6b9e84ff6eb1	2026-02-16	T?t Nguyˆn d n (Lunar New Year) - Day 1
9bfe59f1-5f03-483f-92f1-97c41e1cfb04	2026-02-17	T?t Nguyˆn d n (Lunar New Year) - Day 2
ad1e92dd-e3a9-4abc-91cb-a6742ddfa9e3	2026-02-18	T?t Nguyˆn d n (Lunar New Year) - Day 3
8b7810d2-18db-4fe0-b493-69ec71807636	2026-02-19	T?t Nguyˆn d n (Lunar New Year) - Day 4
4581ae09-a825-409d-9d76-78e07da85764	2026-02-20	T?t Nguyˆn d n (Lunar New Year) - Day 5
0f057296-e36d-4f0a-ac22-45c5c3b881f3	2026-04-27	Hung Kings' Commemoration (Gi? T? H—ng Vuong)
d3683f52-97d6-45d7-b56c-013c70ed8986	2026-04-30	Reunification Day (Ng…y Gi?i ph¢ng mi?n Nam)
2f2e651b-5cbc-40cb-80f1-4da0fc8506b3	2026-05-01	Labour Day (Ng…y Qu?c t? Lao d?ng)
f2d32c42-229d-48c1-98ac-0812c9daa379	2026-09-02	National Day (Qu?c kh nh)
1ae02b43-108a-4113-ad1a-d1c7374227d0	2027-01-01	New Year's Day (T?t Duong l?ch)
04d75557-b534-4643-a7d0-714fabf62026	2027-02-05	T?t Nguyˆn d n (Lunar New Year) - Day 1
3b2ee0bc-308d-474f-9040-55eb9afd5a22	2027-02-06	T?t Nguyˆn d n (Lunar New Year) - Day 2
7e6b6cec-bd87-470c-9a75-c81cfb349651	2027-02-07	T?t Nguyˆn d n (Lunar New Year) - Day 3
96ced0d2-7d59-4485-a679-ce0329a486ce	2027-02-08	T?t Nguyˆn d n (Lunar New Year) - Day 4
8b31a8d2-b9b9-4e94-b027-537081200a94	2027-02-09	T?t Nguyˆn d n (Lunar New Year) - Day 5
2fe30d74-1bd6-4689-81c0-0cffa2ab4b52	2027-04-16	Hung Kings' Commemoration (Gi? T? H—ng Vuong)
b461980b-53f7-407e-b23f-17e75cd57bed	2027-04-30	Reunification Day (Ng…y Gi?i ph¢ng mi?n Nam)
e22a4f2e-c60e-4daf-bab4-8f72b828fa3b	2027-05-01	Labour Day (Ng…y Qu?c t? Lao d?ng)
af15f010-f4c2-4cff-a498-aaad2034fd3e	2027-09-02	National Day (Qu?c kh nh)
a9fea941-a07f-1bed-81a0-7f0d1b3a0000	2026-04-26	Giỗ Tổ Hùng Vương
a9fea941-a07f-1bed-81a0-7f0d1b470001	2026-09-03	Nghỉ liền kề Quốc khánh (3/9)
\.


--
-- Data for Name: interactables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.interactables (id, type) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.jobs (job_id, title, department_id) FROM stdin;
0190abcd-7000-7def-89ab-cdef0123456d	Software Engineer	0190abcd-1234-7def-89ab-cdef01234567
0190abcd-7001-7def-89ab-cdef0123456e	Senior Developer	0190abcd-1234-7def-89ab-cdef01234567
0190abcd-7002-7def-89ab-cdef0123456f	Tech Lead	0190abcd-1234-7def-89ab-cdef01234567
0190abcd-7003-7def-89ab-cdef01234570	Product Manager	0190abcd-1234-7def-89ab-cdef01234567
0190abcd-7004-7def-89ab-cdef01234571	QA Engineer	0190abcd-1234-7def-89ab-cdef01234567
0190abcd-7005-7def-89ab-cdef01234572	DevOps Engineer	0190abcd-1234-7def-89ab-cdef01234567
0190abcd-7006-7def-89ab-cdef01234573	System Administrator	0190abcd-1234-7def-89ab-cdef01234567
0190abcd-7007-7def-89ab-cdef01234574	IT Support Specialist	0190abcd-1234-7def-89ab-cdef01234567
0190abcd-8000-7def-89ab-cdef01234575	Sales Executive	0190abcd-2345-7def-89ab-cdef01234568
0190abcd-8001-7def-89ab-cdef01234576	Senior Sales Executive	0190abcd-2345-7def-89ab-cdef01234568
0190abcd-8002-7def-89ab-cdef01234577	Sales Manager	0190abcd-2345-7def-89ab-cdef01234568
0190abcd-8003-7def-89ab-cdef01234578	Business Development Specialist	0190abcd-2345-7def-89ab-cdef01234568
0190abcd-8004-7def-89ab-cdef01234579	Account Manager	0190abcd-2345-7def-89ab-cdef01234568
0190abcd-9000-7def-89ab-cdef0123457a	Marketing Specialist	0190abcd-3456-7def-89ab-cdef01234569
0190abcd-9001-7def-89ab-cdef0123457b	Content Creator	0190abcd-3456-7def-89ab-cdef01234569
0190abcd-9002-7def-89ab-cdef0123457c	SEO/SEM Specialist	0190abcd-3456-7def-89ab-cdef01234569
0190abcd-9003-7def-89ab-cdef0123457d	Brand Manager	0190abcd-3456-7def-89ab-cdef01234569
0190abcd-9004-7def-89ab-cdef0123457e	Digital Marketing Lead	0190abcd-3456-7def-89ab-cdef01234569
0190abcd-a000-7def-89ab-cdef0123457f	HR Generalist	0190abcd-4567-7def-89ab-cdef0123456a
0190abcd-a001-7def-89ab-cdef01234580	Talent Acquisition Specialist	0190abcd-4567-7def-89ab-cdef0123456a
0190abcd-a002-7def-89ab-cdef01234581	HR Manager	0190abcd-4567-7def-89ab-cdef0123456a
0190abcd-a003-7def-89ab-cdef01234582	Training & Development Specialist	0190abcd-4567-7def-89ab-cdef0123456a
0190abcd-a004-7def-89ab-cdef01234583	Compensation & Benefits Specialist	0190abcd-4567-7def-89ab-cdef0123456a
0190abcd-b000-7def-89ab-cdef01234584	Accountant	0190abcd-5678-7def-89ab-cdef0123456b
0190abcd-b001-7def-89ab-cdef01234585	Senior Accountant	0190abcd-5678-7def-89ab-cdef0123456b
0190abcd-b002-7def-89ab-cdef01234586	Finance Manager	0190abcd-5678-7def-89ab-cdef0123456b
0190abcd-b003-7def-89ab-cdef01234587	Payroll Specialist	0190abcd-5678-7def-89ab-cdef0123456b
0190abcd-b004-7def-89ab-cdef01234588	Financial Analyst	0190abcd-5678-7def-89ab-cdef0123456b
0190abcd-c000-7def-89ab-cdef01234589	Customer Support Representative	0190abcd-6789-7def-89ab-cdef0123456c
0190abcd-c001-7def-89ab-cdef0123458a	Senior Support Specialist	0190abcd-6789-7def-89ab-cdef0123456c
0190abcd-c002-7def-89ab-cdef0123458b	Customer Support Lead	0190abcd-6789-7def-89ab-cdef0123456c
0190abcd-c003-7def-89ab-cdef0123458c	Technical Support Engineer	0190abcd-6789-7def-89ab-cdef0123456c
0190abcd-d000-7def-89ab-cdef0123458d	CEO	0190abcd-7890-7def-89ab-cdef0123456d
893213d9-3245-4382-9b84-f2e82415706b	Department Head of Sales	0190abcd-2345-7def-89ab-cdef01234568
f83436ed-9621-4ec5-b1c4-ac55aa5de01c	Department Head of Marketing & Communication	0190abcd-3456-7def-89ab-cdef01234569
5946cfbd-ad20-419d-bae6-cfe09a261c77	Department Head of Human Resources	0190abcd-4567-7def-89ab-cdef0123456a
3f6dd18d-9644-4413-8f4b-c4c6f5b8da93	Department Head of Finance & Accounting	0190abcd-5678-7def-89ab-cdef0123456b
edcaa4eb-52fb-436c-87b7-6f6d411a72b8	Department Head of Customer Support	0190abcd-6789-7def-89ab-cdef0123456c
47475639-1ac5-40b4-a031-69ee889ce746	Department Head of Executive Leadership	0190abcd-7890-7def-89ab-cdef0123456d
8f18e557-3fd7-4393-9c28-2d9c29e613ca	Department Head of IT	0190abcd-1234-7def-89ab-cdef01234567
584a3e62-c23b-4925-93a6-208ca87e068e	Chairman	0190abcd-7890-7def-89ab-cdef0123456d
1ee9735c-667d-4216-8c29-8845d3d8fe2c	Director	0190abcd-7890-7def-89ab-cdef0123456d
cbe3513b-8a01-49aa-bb63-0fc0056360ae	Deputy Director	0190abcd-7890-7def-89ab-cdef0123456d
\.


--
-- Data for Name: leave_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.leave_requests (request_id, from_date, reason, status, approver_id, requestor_id, created_at, updated_at, to_date, paid_leave_days, rejection_reason) FROM stdin;
a9fea941-a089-1454-81a0-89248e600000	2026-01-09	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	2026-09-10 09:27:50.116331	2026-09-10 09:27:50.116331	2026-01-09	1	\N
a9fea941-a089-1454-81a0-89248e680001	2026-01-12	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	2026-09-10 09:27:50.139548	2026-09-10 09:27:50.139548	2026-01-13	2	\N
a9fea941-a089-1454-81a0-89248e680002	2026-01-14	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	2026-09-10 09:27:50.145769	2026-09-10 09:27:50.145769	2026-01-15	2	\N
a9fea941-a089-1454-81a0-89248e680003	2026-01-08	Nghỉ việc riêng không hưởng lương	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	2026-09-10 09:27:50.150765	2026-09-10 09:27:50.150765	2026-01-09	0	\N
a9fea941-a089-1454-81a0-89248e680004	2026-01-09	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2026-09-10 09:27:50.152274	2026-09-10 09:27:50.152274	2026-01-09	1	\N
a9fea941-a089-1454-81a0-89248e680005	2026-03-11	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	2026-09-10 09:27:50.153283	2026-09-10 09:27:50.153283	2026-03-11	1	\N
a9fea941-a089-1454-81a0-89248e680006	2026-03-13	Nghỉ việc riêng không hưởng lương	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	2026-09-10 09:27:50.153283	2026-09-10 09:27:50.153283	2026-03-13	0	\N
a9fea941-a089-1454-81a0-89248e680007	2026-03-16	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	2026-09-10 09:27:50.154283	2026-09-10 09:27:50.154283	2026-03-17	2	\N
a9fea941-a089-1454-81a0-89248e680008	2026-03-17	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	2026-09-10 09:27:50.155286	2026-09-10 09:27:50.155286	2026-03-17	1	\N
a9fea941-a089-1454-81a0-89248e680009	2026-03-10	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	2026-09-10 09:27:50.157284	2026-09-10 09:27:50.157284	2026-03-11	2	\N
a9fea941-a089-1454-81a0-89248e68000a	2026-03-11	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	2026-09-10 09:27:50.158284	2026-09-10 09:27:50.158284	2026-03-11	1	\N
a9fea941-a089-1454-81a0-89248e68000b	2026-03-12	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	2026-09-10 09:27:50.159282	2026-09-10 09:27:50.159282	2026-03-13	2	\N
a9fea941-a089-1454-81a0-89248e68000c	2026-04-08	Nghỉ việc riêng không hưởng lương	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	2026-09-10 09:27:50.160283	2026-09-10 09:27:50.160283	2026-04-09	0	\N
a9fea941-a089-1454-81a0-89248e68000d	2026-04-10	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	2026-09-10 09:27:50.161283	2026-09-10 09:27:50.161283	2026-04-11	2	\N
a9fea941-a089-1454-81a0-89248e68000e	2026-05-15	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	2026-09-10 09:27:50.162795	2026-09-10 09:27:50.162795	2026-05-15	1	\N
a9fea941-a089-1454-81a0-89248e69000f	2026-06-09	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	2026-09-10 09:27:50.164809	2026-09-10 09:27:50.164809	2026-06-09	1	\N
a9fea941-a089-1454-81a0-89248e690010	2026-06-12	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	2026-09-10 09:27:50.165811	2026-09-10 09:27:50.165811	2026-06-13	2	\N
a9fea941-a089-1454-81a0-89248e690011	2026-06-14	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	2026-09-10 09:27:50.16681	2026-09-10 09:27:50.16681	2026-06-15	2	\N
a9fea941-a089-1454-81a0-89248e690012	2026-06-08	Nghỉ việc riêng không hưởng lương	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	2026-09-10 09:27:50.16681	2026-09-10 09:27:50.16681	2026-06-09	0	\N
a9fea941-a089-1454-81a0-89248e690013	2026-06-09	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2026-09-10 09:27:50.16781	2026-09-10 09:27:50.16781	2026-06-09	1	\N
a9fea941-a089-1454-81a0-89248e690014	2026-08-11	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	2026-09-10 09:27:50.168813	2026-09-10 09:27:50.168813	2026-08-11	1	\N
a9fea941-a089-1454-81a0-89248e690015	2026-08-13	Nghỉ việc riêng không hưởng lương	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	2026-09-10 09:27:50.169815	2026-09-10 09:27:50.169815	2026-08-13	0	\N
a9fea941-a089-1454-81a0-89248e690016	2026-08-16	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	2026-09-10 09:27:50.170811	2026-09-10 09:27:50.170811	2026-08-17	2	\N
a9fea941-a089-1454-81a0-89248e690017	2026-08-17	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	2026-09-10 09:27:50.173317	2026-09-10 09:27:50.173317	2026-08-17	1	\N
a9fea941-a089-1454-81a0-89248e690018	2026-08-10	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	2026-09-10 09:27:50.17634	2026-09-10 09:27:50.17634	2026-08-11	2	\N
a9fea941-a089-1454-81a0-89248e690019	2026-08-11	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	2026-09-10 09:27:50.17934	2026-09-10 09:27:50.17934	2026-08-11	1	\N
a9fea941-a089-1454-81a0-89248e6a001a	2026-08-12	Nghỉ phép năm giải quyết việc gia đình	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	2026-09-10 09:27:50.181338	2026-09-10 09:27:50.181338	2026-08-13	2	\N
\.


--
-- Data for Name: monthly_payroll_summaries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.monthly_payroll_summaries (summary_id, period_month, period_year, total_employees, total_gross_pay, total_net_pay, total_basic_pay, total_overtime_pay, total_bonus_pay, total_allowance_pay, total_personal_income_tax, total_employee_insurance, total_company_insurance, total_union_fee, total_company_cost, status, approved_by, approved_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: monthly_timesheets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.monthly_timesheets (timesheet_id, user_id, period_month, period_year, standard_working_days, actual_worked_days, actual_work_hours, late_count, total_late_minutes, early_departure_count, absent_days, paid_leave_days, unpaid_leave_days, total_actual_ot_hours, total_paid_ot_hours, ot_details, status, note, locked_at, locked_by, created_at, updated_at) FROM stdin;
a9fea941-a089-1454-81a0-892518950b37	35337165-e0d0-4dd1-9c67-cc48180363af	1	2026	21	21.00	161.00	5	97	3	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:24.869044+00	2026-09-10 02:28:31.657793+00
a9fea941-a089-1454-81a0-8925201e0b3b	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	1	2026	21	19.00	163.62	3	54	0	0.00	2.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:26.794968+00	2026-09-10 02:28:31.671322+00
a9fea941-a089-1454-81a0-89251a730b38	5934b552-2406-4a70-b69b-f0abec6bdd28	1	2026	21	18.00	149.37	0	0	0	2.00	1.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:25.34552+00	2026-09-10 02:28:31.669322+00
a9fea941-a089-1454-81a0-89251c680b39	fca9aa46-b141-415f-ab4c-9f336bdfd46e	1	2026	21	20.00	153.50	3	60	3	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:25.846988+00	2026-09-10 02:28:31.670324+00
a9fea941-a089-1454-81a0-89251e1b0b3a	6b39462f-1134-4e9a-9a06-f2b3687940b7	1	2026	21	20.00	156.47	1	17	0	1.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:26.281468+00	2026-09-10 02:28:31.671322+00
a9fea941-a089-1454-81a0-892521ea0b3c	c6322771-714d-4d31-a732-47f86ac8465e	1	2026	21	21.00	163.27	3	66	3	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:27.256022+00	2026-09-10 02:28:31.672323+00
a9fea941-a089-1454-81a0-892523f70b3d	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1	2026	21	19.00	164.13	3	59	1	0.00	2.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:27.782849+00	2026-09-10 02:28:31.674873+00
a9fea941-a089-1454-81a0-892525c90b3e	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	1	2026	21	21.00	164.62	1	17	1	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:28.248414+00	2026-09-10 02:28:31.676839+00
a9fea941-a089-1454-81a0-892527b30b3f	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	1	2026	21	21.00	160.63	3	60	6	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:28.746916+00	2026-09-10 02:28:31.677837+00
a9fea941-a089-1454-81a0-8925298a0b40	d1f7cf77-4784-4b35-8d12-f2833e3bb066	1	2026	21	21.00	162.98	2	43	4	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:29.207611+00	2026-09-10 02:28:31.679881+00
a9fea941-a089-1454-81a0-89252b8f0b41	951f937f-2724-4cf5-9b4f-7528f736d782	1	2026	21	17.50	153.47	0	0	0	0.00	2.00	2.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:29.72513+00	2026-09-10 02:28:31.681836+00
a9fea941-a089-1454-81a0-89252d670b42	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	1	2026	21	20.00	162.20	2	43	5	0.00	1.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:30.197112+00	2026-09-10 02:28:31.684348+00
a9fea941-a089-1454-81a0-89252f5d0b43	9fbc67a0-b671-479c-9b46-3076df068741	1	2026	21	21.00	163.72	2	35	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:30.69888+00	2026-09-10 02:28:31.685346+00
a9fea941-a089-1454-81a0-892531120b44	cf26d867-49f1-4c12-b35b-c79bfb2884fc	1	2026	21	20.00	153.18	3	60	4	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:31.136383+00	2026-09-10 02:28:31.685346+00
a9fea941-a089-1454-81a0-892533050b45	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	1	2026	21	21.00	164.08	1	18	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:31.638682+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:31.636697+00	2026-09-10 02:28:31.686885+00
a9fea941-a089-1454-81a0-892534e80b46	35337165-e0d0-4dd1-9c67-cc48180363af	2	2026	15	15.00	118.75	0	0	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:32.128516+00	2026-09-10 02:28:38.272987+00
a9fea941-a089-1454-81a0-892536d50b47	5934b552-2406-4a70-b69b-f0abec6bdd28	2	2026	15	13.50	104.50	2	40	2	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:32.62288+00	2026-09-10 02:28:38.275984+00
a9fea941-a089-1454-81a0-8925386a0b48	fca9aa46-b141-415f-ab4c-9f336bdfd46e	2	2026	15	15.00	116.95	4	78	0	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:33.024465+00	2026-09-10 02:28:38.276984+00
a9fea941-a089-1454-81a0-89253a370b49	6b39462f-1134-4e9a-9a06-f2b3687940b7	2	2026	15	13.50	107.00	0	0	0	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:33.488172+00	2026-09-10 02:28:38.277985+00
a9fea941-a089-1454-81a0-89253bd00b4a	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	2	2026	15	14.50	111.37	3	60	3	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:33.888872+00	2026-09-10 02:28:38.279496+00
a9fea941-a089-1454-81a0-89253d630b4b	c6322771-714d-4d31-a732-47f86ac8465e	2	2026	15	15.00	117.42	0	0	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:34.299627+00	2026-09-10 02:28:38.280496+00
a9fea941-a089-1454-81a0-892542e50b4e	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	2	2026	15	15.00	115.42	5	92	0	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:35.706155+00	2026-09-10 02:28:38.281494+00
a9fea941-a089-1454-81a0-89253f810b4c	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	2	2026	15	15.00	117.25	0	0	0	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:34.839403+00	2026-09-10 02:28:38.280496+00
a9fea941-a089-1454-81a0-8925410d0b4d	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	2	2026	15	15.00	115.03	3	64	3	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:35.237329+00	2026-09-10 02:28:38.281494+00
a9fea941-a089-1454-81a0-8925446c0b4f	d1f7cf77-4784-4b35-8d12-f2833e3bb066	2	2026	15	13.50	105.62	0	0	0	1.00	0.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:36.097719+00	2026-09-10 02:28:38.284509+00
a9fea941-a089-1454-81a0-892546380b50	951f937f-2724-4cf5-9b4f-7528f736d782	2	2026	15	15.00	116.53	2	45	2	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:36.557368+00	2026-09-10 02:28:38.286494+00
a9fea941-a089-1454-81a0-892547cf0b51	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2	2026	15	15.00	117.75	0	0	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:36.971562+00	2026-09-10 02:28:38.288001+00
a9fea941-a089-1454-81a0-892549b50b52	9fbc67a0-b671-479c-9b46-3076df068741	2	2026	15	12.50	98.83	0	0	0	2.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:37.456501+00	2026-09-10 02:28:38.288001+00
a9fea941-a089-1454-81a0-89254b470b53	cf26d867-49f1-4c12-b35b-c79bfb2884fc	2	2026	15	15.00	118.13	0	0	0	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:37.851515+00	2026-09-10 02:28:38.289008+00
a9fea941-a089-1454-81a0-89254ced0b54	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	2	2026	15	13.00	102.83	0	0	0	1.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:38.263293+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:38.259783+00	2026-09-10 02:28:38.290014+00
a9fea941-a089-1454-81a0-89254f2a0b55	35337165-e0d0-4dd1-9c67-cc48180363af	3	2026	22	21.00	162.55	2	40	2	1.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:38.850623+00	2026-09-10 02:28:45.395834+00
a9fea941-a089-1454-81a0-892551190b56	5934b552-2406-4a70-b69b-f0abec6bdd28	3	2026	22	22.00	170.12	4	84	2	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:39.345004+00	2026-09-10 02:28:45.39914+00
a9fea941-a089-1454-81a0-892552ca0b57	fca9aa46-b141-415f-ab4c-9f336bdfd46e	3	2026	22	22.00	171.13	3	51	0	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:39.776681+00	2026-09-10 02:28:45.40121+00
a9fea941-a089-1454-81a0-892554940b58	6b39462f-1134-4e9a-9a06-f2b3687940b7	3	2026	22	21.00	170.25	1	21	5	0.00	1.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:40.242048+00	2026-09-10 02:28:45.404339+00
a9fea941-a089-1454-81a0-892556630b59	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	3	2026	22	18.00	141.20	0	0	0	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:40.710931+00	2026-09-10 02:28:45.419687+00
a9fea941-a089-1454-81a0-892558720b5a	c6322771-714d-4d31-a732-47f86ac8465e	3	2026	22	18.00	149.92	0	0	0	2.00	1.00	1.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:41.225367+00	2026-09-10 02:28:45.433307+00
a9fea941-a089-1454-81a0-89255a2a0b5b	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	3	2026	22	20.00	156.45	1	20	1	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:41.667759+00	2026-09-10 02:28:45.437151+00
a9fea941-a089-1454-81a0-89255be20b5c	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	3	2026	22	20.00	155.80	1	20	2	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:42.104275+00	2026-09-10 02:28:45.44605+00
a9fea941-a089-1454-81a0-89255df70b5d	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	3	2026	22	18.50	161.87	0	0	0	1.00	2.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:42.635648+00	2026-09-10 02:28:45.456173+00
a9fea941-a089-1454-81a0-89255faa0b5e	d1f7cf77-4784-4b35-8d12-f2833e3bb066	3	2026	22	19.00	157.02	1	16	0	2.00	1.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:43.072826+00	2026-09-10 02:28:45.463181+00
a9fea941-a089-1454-81a0-8925616a0b5f	951f937f-2724-4cf5-9b4f-7528f736d782	3	2026	22	22.00	170.73	5	98	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:43.531689+00	2026-09-10 02:28:45.470705+00
a9fea941-a089-1454-81a0-8925636d0b60	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	3	2026	22	19.50	153.43	0	0	0	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:44.035642+00	2026-09-10 02:28:45.479255+00
a9fea941-a089-1454-81a0-892565390b61	9fbc67a0-b671-479c-9b46-3076df068741	3	2026	22	20.00	169.05	3	63	5	0.00	2.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:44.494089+00	2026-09-10 02:28:45.486783+00
a9fea941-a089-1454-81a0-892566f70b62	cf26d867-49f1-4c12-b35b-c79bfb2884fc	3	2026	22	21.00	170.28	5	94	1	0.00	1.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:44.941157+00	2026-09-10 02:28:45.494786+00
a9fea941-a089-1454-81a0-892568bd0b63	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	3	2026	22	20.00	169.60	2	42	5	0.00	2.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:45.38581+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:45.381273+00	2026-09-10 02:28:45.498361+00
a9fea941-a089-1454-81a0-89256b420b64	35337165-e0d0-4dd1-9c67-cc48180363af	4	2026	20	17.00	146.77	3	60	3	0.00	2.00	2.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:46.033998+00	2026-09-10 02:28:52.434064+00
a9fea941-a089-1454-81a0-89256ce90b65	5934b552-2406-4a70-b69b-f0abec6bdd28	4	2026	20	20.00	156.60	2	35	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:46.450559+00	2026-09-10 02:28:52.43507+00
a9fea941-a089-1454-81a0-89256eb60b66	fca9aa46-b141-415f-ab4c-9f336bdfd46e	4	2026	20	16.00	133.10	1	20	1	1.00	1.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:46.919626+00	2026-09-10 02:28:52.437109+00
a9fea941-a089-1454-81a0-892570930b67	6b39462f-1134-4e9a-9a06-f2b3687940b7	4	2026	20	20.00	156.40	3	57	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:47.398259+00	2026-09-10 02:28:52.438067+00
a9fea941-a089-1454-81a0-8925722b0b68	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	4	2026	20	20.00	155.87	4	70	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:47.801078+00	2026-09-10 02:28:52.439167+00
a9fea941-a089-1454-81a0-892573ef0b69	c6322771-714d-4d31-a732-47f86ac8465e	4	2026	20	19.50	149.75	2	43	5	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:48.255215+00	2026-09-10 02:28:52.440126+00
a9fea941-a089-1454-81a0-8925761f0b6a	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	4	2026	20	20.00	153.23	5	106	3	0.00	0.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:48.816998+00	2026-09-10 02:28:52.441089+00
a9fea941-a089-1454-81a0-892577d10b6b	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	4	2026	20	18.00	141.32	0	0	0	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:49.249687+00	2026-09-10 02:28:52.442199+00
a9fea941-a089-1454-81a0-892579850b6c	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	4	2026	20	19.00	145.53	3	60	4	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:49.683244+00	2026-09-10 02:28:52.447821+00
a9fea941-a089-1454-81a0-89257b2b0b6d	d1f7cf77-4784-4b35-8d12-f2833e3bb066	4	2026	20	20.00	154.02	5	99	2	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:50.100626+00	2026-09-10 02:28:52.448823+00
a9fea941-a089-1454-81a0-89257d190b6e	951f937f-2724-4cf5-9b4f-7528f736d782	4	2026	20	17.50	137.75	0	0	0	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:50.607763+00	2026-09-10 02:28:52.448823+00
a9fea941-a089-1454-81a0-89257ec70b6f	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	4	2026	20	19.00	146.40	1	20	5	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:51.030856+00	2026-09-10 02:28:52.449709+00
a9fea941-a089-1454-81a0-8925807e0b70	9fbc67a0-b671-479c-9b46-3076df068741	4	2026	20	20.00	155.17	5	96	0	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:51.469078+00	2026-09-10 02:28:52.45171+00
a9fea941-a089-1454-81a0-892582660b71	cf26d867-49f1-4c12-b35b-c79bfb2884fc	4	2026	20	19.50	149.80	2	40	5	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:51.958097+00	2026-09-10 02:28:52.45171+00
a9fea941-a089-1454-81a0-8925843a0b72	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	4	2026	20	20.00	155.70	4	76	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:52.425365+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:52.417766+00	2026-09-10 02:28:52.453709+00
a9fea941-a089-1454-81a0-8925863d0b73	35337165-e0d0-4dd1-9c67-cc48180363af	5	2026	20	20.00	154.73	1	23	4	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:52.940625+00	2026-09-10 02:28:59.392254+00
a9fea941-a089-1454-81a0-892588290b74	5934b552-2406-4a70-b69b-f0abec6bdd28	5	2026	20	20.00	156.83	0	0	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:53.432787+00	2026-09-10 02:28:59.394217+00
a9fea941-a089-1454-81a0-892589eb0b75	fca9aa46-b141-415f-ab4c-9f336bdfd46e	5	2026	20	20.00	151.45	5	105	6	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:53.886861+00	2026-09-10 02:28:59.400721+00
a9fea941-a089-1454-81a0-89258bac0b76	6b39462f-1134-4e9a-9a06-f2b3687940b7	5	2026	20	20.00	157.00	0	0	0	0.00	0.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:54.334388+00	2026-09-10 02:28:59.401729+00
a9fea941-a089-1454-81a0-89258d640b77	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	5	2026	20	20.00	153.65	5	105	3	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:54.7703+00	2026-09-10 02:28:59.403738+00
a9fea941-a089-1454-81a0-89258f530b78	c6322771-714d-4d31-a732-47f86ac8465e	5	2026	20	20.00	154.80	6	121	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:55.264776+00	2026-09-10 02:28:59.405736+00
a9fea941-a089-1454-81a0-892591130b79	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	5	2026	20	20.00	155.17	5	90	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:55.713405+00	2026-09-10 02:28:59.407053+00
a9fea941-a089-1454-81a0-892592df0b7a	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	5	2026	20	19.00	155.05	5	102	0	0.00	1.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:56.174301+00	2026-09-10 02:28:59.408061+00
a9fea941-a089-1454-81a0-892594940b7b	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	5	2026	20	20.00	154.72	5	100	2	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:56.612639+00	2026-09-10 02:28:59.412583+00
a9fea941-a089-1454-81a0-8925966b0b7c	d1f7cf77-4784-4b35-8d12-f2833e3bb066	5	2026	20	18.50	142.28	1	20	5	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:57.091669+00	2026-09-10 02:28:59.420779+00
a9fea941-a089-1454-81a0-892598350b7d	951f937f-2724-4cf5-9b4f-7528f736d782	5	2026	20	18.00	139.32	1	20	4	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:57.544854+00	2026-09-10 02:28:59.421825+00
a9fea941-a089-1454-81a0-89259a320b7e	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	5	2026	20	20.00	153.32	6	117	2	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:58.048879+00	2026-09-10 02:28:59.422853+00
a9fea941-a089-1454-81a0-89259bea0b7f	9fbc67a0-b671-479c-9b46-3076df068741	5	2026	20	20.00	157.67	0	0	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:58.488542+00	2026-09-10 02:28:59.422853+00
a9fea941-a089-1454-81a0-89259da70b80	cf26d867-49f1-4c12-b35b-c79bfb2884fc	5	2026	20	17.00	133.08	0	0	0	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:58.935938+00	2026-09-10 02:28:59.423928+00
a9fea941-a089-1454-81a0-89259f680b81	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5	2026	20	20.00	157.33	0	0	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:28:59.384632+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:59.382626+00	2026-09-10 02:28:59.423928+00
a9fea941-a089-1454-81a0-8925a3710b83	5934b552-2406-4a70-b69b-f0abec6bdd28	6	2026	22	19.50	158.72	3	62	2	0.00	1.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:00.413396+00	2026-09-10 02:29:06.71894+00
a9fea941-a089-1454-81a0-8925a1970b82	35337165-e0d0-4dd1-9c67-cc48180363af	6	2026	22	22.00	172.33	2	37	0	0.00	0.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:28:59.942177+00	2026-09-10 02:29:06.717947+00
a9fea941-a089-1454-81a0-8925a5380b84	fca9aa46-b141-415f-ab4c-9f336bdfd46e	6	2026	22	22.00	170.90	5	92	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:00.869396+00	2026-09-10 02:29:06.719941+00
a9fea941-a089-1454-81a0-8925a7250b85	6b39462f-1134-4e9a-9a06-f2b3687940b7	6	2026	22	20.50	161.00	0	0	1	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:01.363932+00	2026-09-10 02:29:06.719941+00
a9fea941-a089-1454-81a0-8925a9030b86	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	6	2026	22	19.00	156.18	1	20	2	0.00	1.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:01.842566+00	2026-09-10 02:29:06.722266+00
a9fea941-a089-1454-81a0-8925aed40b89	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	6	2026	22	21.00	161.80	1	20	6	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:03.331059+00	2026-09-10 02:29:06.734219+00
a9fea941-a089-1454-81a0-8925aafa0b87	c6322771-714d-4d31-a732-47f86ac8465e	6	2026	22	22.00	172.95	0	0	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:02.345227+00	2026-09-10 02:29:06.722266+00
a9fea941-a089-1454-81a0-8925ad160b88	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	6	2026	22	20.50	168.83	0	0	0	0.00	1.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:02.884763+00	2026-09-10 02:29:06.732221+00
a9fea941-a089-1454-81a0-8925b0a20b8a	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	6	2026	22	22.00	171.67	2	33	0	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:03.793551+00	2026-09-10 02:29:06.735218+00
a9fea941-a089-1454-81a0-8925b2610b8b	d1f7cf77-4784-4b35-8d12-f2833e3bb066	6	2026	22	19.50	153.10	0	0	0	2.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:04.239598+00	2026-09-10 02:29:06.736282+00
a9fea941-a089-1454-81a0-8925b4830b8c	951f937f-2724-4cf5-9b4f-7528f736d782	6	2026	22	20.00	170.87	5	105	1	0.00	2.00	2.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:04.785896+00	2026-09-10 02:29:06.737334+00
a9fea941-a089-1454-81a0-8925b6500b8d	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	6	2026	22	20.00	164.80	1	16	0	1.00	1.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:05.244507+00	2026-09-10 02:29:06.741411+00
a9fea941-a089-1454-81a0-8925b8110b8e	9fbc67a0-b671-479c-9b46-3076df068741	6	2026	22	19.50	153.03	0	0	1	2.00	0.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:05.696079+00	2026-09-10 02:29:06.743472+00
a9fea941-a089-1454-81a0-8925ba2c0b8f	cf26d867-49f1-4c12-b35b-c79bfb2884fc	6	2026	22	22.00	171.80	3	51	0	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:06.240261+00	2026-09-10 02:29:06.747471+00
a9fea941-a089-1454-81a0-8925bc010b90	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	6	2026	22	20.00	157.02	0	0	1	1.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:06.702298+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:06.696213+00	2026-09-10 02:29:06.749921+00
a9fea941-a089-1454-81a0-8925c7bf0b96	c6322771-714d-4d31-a732-47f86ac8465e	7	2026	23	22.50	175.95	0	0	2	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:09.711002+00	2026-09-10 02:29:14.076985+00
a9fea941-a089-1454-81a0-8925be210b91	35337165-e0d0-4dd1-9c67-cc48180363af	7	2026	23	20.00	157.32	0	0	0	2.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:07.249891+00	2026-09-10 02:29:14.072983+00
a9fea941-a089-1454-81a0-8925c0280b92	5934b552-2406-4a70-b69b-f0abec6bdd28	7	2026	23	23.00	177.20	4	86	4	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:07.769714+00	2026-09-10 02:29:14.073984+00
a9fea941-a089-1454-81a0-8925c1fd0b93	fca9aa46-b141-415f-ab4c-9f336bdfd46e	7	2026	23	22.50	177.12	0	0	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:08.240267+00	2026-09-10 02:29:14.074984+00
a9fea941-a089-1454-81a0-8925c3d60b94	6b39462f-1134-4e9a-9a06-f2b3687940b7	7	2026	23	22.50	171.12	5	93	6	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:08.709012+00	2026-09-10 02:29:14.076097+00
a9fea941-a089-1454-81a0-8925c5b80b95	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	7	2026	23	21.00	165.17	0	0	0	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:09.192068+00	2026-09-10 02:29:14.076985+00
a9fea941-a089-1454-81a0-8925c97f0b97	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	7	2026	23	19.50	152.17	0	0	2	2.00	0.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:10.16056+00	2026-09-10 02:29:14.078085+00
a9fea941-a089-1454-81a0-8925cb4e0b98	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	7	2026	23	20.50	161.10	0	0	0	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:10.621143+00	2026-09-10 02:29:14.078085+00
a9fea941-a089-1454-81a0-8925cd620b99	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	7	2026	23	19.50	151.42	2	40	2	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:11.15528+00	2026-09-10 02:29:14.078085+00
a9fea941-a089-1454-81a0-8925cf410b9a	d1f7cf77-4784-4b35-8d12-f2833e3bb066	7	2026	23	23.00	179.95	2	41	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:11.63325+00	2026-09-10 02:29:14.088706+00
a9fea941-a089-1454-81a0-8925d1180b9b	951f937f-2724-4cf5-9b4f-7528f736d782	7	2026	23	22.00	172.00	2	33	0	1.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:12.104579+00	2026-09-10 02:29:14.089715+00
a9fea941-a089-1454-81a0-8925d3250b9c	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	7	2026	23	21.00	162.77	2	40	2	2.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:12.625946+00	2026-09-10 02:29:14.090869+00
a9fea941-a089-1454-81a0-8925d4ff0b9d	9fbc67a0-b671-479c-9b46-3076df068741	7	2026	23	21.50	165.72	3	57	4	0.00	0.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:13.104575+00	2026-09-10 02:29:14.09387+00
a9fea941-a089-1454-81a0-8925d6ed0b9e	cf26d867-49f1-4c12-b35b-c79bfb2884fc	7	2026	23	23.00	176.38	4	83	5	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:13.595176+00	2026-09-10 02:29:14.099874+00
a9fea941-a089-1454-81a0-8925d8c40b9f	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	7	2026	23	22.00	168.42	4	75	5	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	LOCKED	\N	2026-09-10 02:29:14.063379+00	5a7e56d6-9457-4cfa-8b62-68f562953424	2026-09-10 02:29:14.061358+00	2026-09-10 02:29:14.110814+00
a9fea941-a089-1454-81a0-8925db040ba0	35337165-e0d0-4dd1-9c67-cc48180363af	8	2026	21	20.50	156.83	3	63	6	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:14.663873+00	2026-09-10 02:29:14.663873+00
a9fea941-a089-1454-81a0-8925dcd90ba1	5934b552-2406-4a70-b69b-f0abec6bdd28	8	2026	21	21.00	163.85	3	51	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:15.125934+00	2026-09-10 02:29:15.125934+00
a9fea941-a089-1454-81a0-8925dea20ba2	fca9aa46-b141-415f-ab4c-9f336bdfd46e	8	2026	21	19.00	148.87	0	0	1	2.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:15.586471+00	2026-09-10 02:29:15.586471+00
a9fea941-a089-1454-81a0-8925e0c60ba3	6b39462f-1134-4e9a-9a06-f2b3687940b7	8	2026	21	20.00	162.67	5	95	0	0.00	1.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:16.131935+00	2026-09-10 02:29:16.131935+00
a9fea941-a089-1454-81a0-8925e2d50ba4	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	8	2026	21	21.00	165.08	1	23	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:16.664798+00	2026-09-10 02:29:16.664798+00
a9fea941-a089-1454-81a0-8925e4a60ba5	c6322771-714d-4d31-a732-47f86ac8465e	8	2026	21	19.50	157.32	4	79	4	0.00	1.00	1.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:17.125009+00	2026-09-10 02:29:17.125009+00
a9fea941-a089-1454-81a0-8925e6ab0ba6	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	8	2026	21	21.00	161.55	2	36	5	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:17.642867+00	2026-09-10 02:29:17.642867+00
a9fea941-a089-1454-81a0-8925e88b0ba7	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	8	2026	21	21.00	164.18	3	55	0	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:18.1231+00	2026-09-10 02:29:18.1231+00
a9fea941-a089-1454-81a0-8925ea5d0ba8	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	8	2026	21	20.00	161.40	3	63	5	0.00	1.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:18.590045+00	2026-09-10 02:29:18.590045+00
a9fea941-a089-1454-81a0-8925ec580ba9	d1f7cf77-4784-4b35-8d12-f2833e3bb066	8	2026	21	20.00	162.13	6	110	1	0.00	1.00	0.00	7.00	14.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:19.096501+00	2026-09-10 02:29:19.096501+00
a9fea941-a089-1454-81a0-8925ee6c0baa	951f937f-2724-4cf5-9b4f-7528f736d782	8	2026	21	21.00	163.58	1	20	1	0.00	0.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:19.630409+00	2026-09-10 02:29:19.630409+00
a9fea941-a089-1454-81a0-8925f0300bab	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	8	2026	21	19.50	151.00	3	61	2	0.00	0.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:20.083023+00	2026-09-10 02:29:20.083023+00
a9fea941-a089-1454-81a0-8925f2270bac	9fbc67a0-b671-479c-9b46-3076df068741	8	2026	21	19.00	163.38	5	105	0	0.00	2.00	0.00	9.50	17.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}, {"type": "NORMAL_NIGHT", "hours": 3.0, "label": "Ngày thường - Ban đêm (200%)", "paidHours": 6.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:20.581923+00	2026-09-10 02:29:20.581923+00
a9fea941-a089-1454-81a0-8925f4550bad	cf26d867-49f1-4c12-b35b-c79bfb2884fc	8	2026	21	17.50	143.52	2	40	2	1.00	1.00	0.00	6.50	11.75	[{"type": "NORMAL_DAY", "hours": 2.5, "label": "Ngày thường - Ban ngày (150%)", "paidHours": 3.75, "multiplier": 1.5}, {"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:21.13712+00	2026-09-10 02:29:21.13712+00
a9fea941-a089-1454-81a0-8925f6450bae	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	8	2026	21	19.00	163.05	5	100	0	0.00	2.00	0.00	4.00	8.00	[{"type": "WEEKEND_DAY", "hours": 4.0, "label": "Cuối tuần - Ban ngày (200%)", "paidHours": 8.0, "multiplier": 2.0}]	DRAFT	\N	\N	\N	2026-09-10 02:29:21.616958+00	2026-09-10 02:29:21.616958+00
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (notification_id, count, created_at, entity_id, entity_type, is_read, is_seen, type, updated_at, recipent_id, sender_id) FROM stdin;
\.


--
-- Data for Name: overtime_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.overtime_records (overtime_record_id, approved_date, approved_end_time, approved_start_time, clock_in_time, clock_out_time, is_holiday, is_night_time, is_weekend, status, approver_id, requestor_id, reason, rejection_reason) FROM stdin;
a9fea941-a089-1454-81a0-892490bb001b	2026-01-06	2026-01-06 20:00:00	2026-01-06 17:30:00	2026-01-06 17:30:00	2026-01-06 20:00:00	f	f	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490bc001c	2026-01-17	2026-01-17 12:30:00	2026-01-17 08:30:00	2026-01-17 08:30:00	2026-01-17 12:30:00	f	f	t	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490bc001d	2026-01-22	2026-01-23 01:00:00	2026-01-22 22:00:00	2026-01-22 22:00:00	2026-01-23 01:00:00	f	t	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490bc001e	2026-01-07	2026-01-07 20:00:00	2026-01-07 17:30:00	2026-01-07 17:30:00	2026-01-07 20:00:00	f	f	f	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490bc001f	2026-01-17	2026-01-17 12:30:00	2026-01-17 08:30:00	2026-01-17 08:30:00	2026-01-17 12:30:00	f	f	t	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490bc0020	2026-01-08	2026-01-08 20:00:00	2026-01-08 17:30:00	2026-01-08 17:30:00	2026-01-08 20:00:00	f	f	f	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490bc0021	2026-01-17	2026-01-17 12:30:00	2026-01-17 08:30:00	2026-01-17 08:30:00	2026-01-17 12:30:00	f	f	t	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490bd0022	2026-01-09	2026-01-09 20:00:00	2026-01-09 17:30:00	2026-01-09 17:30:00	2026-01-09 20:00:00	f	f	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490bd0023	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490bd0024	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490bd0025	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490bd0026	2026-01-12	2026-01-12 20:00:00	2026-01-12 17:30:00	2026-01-12 17:30:00	2026-01-12 20:00:00	f	f	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490bd0027	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490bd0028	2026-01-23	2026-01-24 01:00:00	2026-01-23 22:00:00	2026-01-23 22:00:00	2026-01-24 01:00:00	f	t	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490bd0029	2026-01-13	2026-01-13 20:00:00	2026-01-13 17:30:00	2026-01-13 17:30:00	2026-01-13 20:00:00	f	f	f	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490bd002a	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490be002b	2026-01-14	2026-01-14 20:00:00	2026-01-14 17:30:00	2026-01-14 17:30:00	2026-01-14 20:00:00	f	f	f	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490be002c	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490be002d	2026-01-15	2026-01-15 20:00:00	2026-01-15 17:30:00	2026-01-15 17:30:00	2026-01-15 20:00:00	f	f	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490be002e	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490be002f	2026-01-26	2026-01-27 01:00:00	2026-01-26 22:00:00	2026-01-26 22:00:00	2026-01-27 01:00:00	f	t	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490be0030	2026-01-16	2026-01-16 20:00:00	2026-01-16 17:30:00	2026-01-16 17:30:00	2026-01-16 20:00:00	f	f	f	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490be0031	2026-01-17	2026-01-17 12:30:00	2026-01-17 08:30:00	2026-01-17 08:30:00	2026-01-17 12:30:00	f	f	t	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c00032	2026-01-17	2026-01-17 12:30:00	2026-01-17 08:30:00	2026-01-17 08:30:00	2026-01-17 12:30:00	f	f	t	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c00033	2026-01-06	2026-01-06 20:00:00	2026-01-06 17:30:00	2026-01-06 17:30:00	2026-01-06 20:00:00	f	f	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c00034	2026-01-17	2026-01-17 12:30:00	2026-01-17 08:30:00	2026-01-17 08:30:00	2026-01-17 12:30:00	f	f	t	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c00035	2026-01-07	2026-01-07 20:00:00	2026-01-07 17:30:00	2026-01-07 17:30:00	2026-01-07 20:00:00	f	f	f	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c00036	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c00037	2026-01-08	2026-01-08 20:00:00	2026-01-08 17:30:00	2026-01-08 17:30:00	2026-01-08 20:00:00	f	f	f	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c00038	2026-01-24	2026-01-24 12:30:00	2026-01-24 08:30:00	2026-01-24 08:30:00	2026-01-24 12:30:00	f	f	t	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c20039	2026-02-06	2026-02-06 20:00:00	2026-02-06 17:30:00	2026-02-06 17:30:00	2026-02-06 20:00:00	f	f	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c2003a	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c2003b	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c2003c	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c2003d	2026-02-09	2026-02-09 20:00:00	2026-02-09 17:30:00	2026-02-09 17:30:00	2026-02-09 20:00:00	f	f	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c2003e	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c2003f	2026-02-25	2026-02-26 01:00:00	2026-02-25 22:00:00	2026-02-25 22:00:00	2026-02-26 01:00:00	f	t	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c30040	2026-02-10	2026-02-10 20:00:00	2026-02-10 17:30:00	2026-02-10 17:30:00	2026-02-10 20:00:00	f	f	f	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c30041	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c30042	2026-02-11	2026-02-11 20:00:00	2026-02-11 17:30:00	2026-02-11 17:30:00	2026-02-11 20:00:00	f	f	f	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c30043	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c30044	2026-02-12	2026-02-12 20:00:00	2026-02-12 17:30:00	2026-02-12 17:30:00	2026-02-12 20:00:00	f	f	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c30045	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c30046	2026-02-23	2026-02-24 01:00:00	2026-02-23 22:00:00	2026-02-23 22:00:00	2026-02-24 01:00:00	f	t	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c30047	2026-02-13	2026-02-13 20:00:00	2026-02-13 17:30:00	2026-02-13 17:30:00	2026-02-13 20:00:00	f	f	f	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c30048	2026-02-28	2026-02-28 12:30:00	2026-02-28 08:30:00	2026-02-28 08:30:00	2026-02-28 12:30:00	f	f	t	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c30049	2026-02-28	2026-02-28 12:30:00	2026-02-28 08:30:00	2026-02-28 08:30:00	2026-02-28 12:30:00	f	f	t	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c3004a	2026-02-28	2026-02-28 12:30:00	2026-02-28 08:30:00	2026-02-28 08:30:00	2026-02-28 12:30:00	f	f	t	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c4004b	2026-02-26	2026-02-27 01:00:00	2026-02-26 22:00:00	2026-02-26 22:00:00	2026-02-27 01:00:00	f	t	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c4004c	2026-02-16	2026-02-16 20:00:00	2026-02-16 17:30:00	2026-02-16 17:30:00	2026-02-16 20:00:00	f	f	f	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c4004d	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c4004e	2026-02-17	2026-02-17 20:00:00	2026-02-17 17:30:00	2026-02-17 17:30:00	2026-02-17 20:00:00	f	f	f	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c4004f	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c40050	2026-02-06	2026-02-06 20:00:00	2026-02-06 17:30:00	2026-02-06 17:30:00	2026-02-06 20:00:00	f	f	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c40051	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c40052	2026-02-24	2026-02-25 01:00:00	2026-02-24 22:00:00	2026-02-24 22:00:00	2026-02-25 01:00:00	f	t	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c40053	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c40054	2026-02-21	2026-02-21 12:30:00	2026-02-21 08:30:00	2026-02-21 08:30:00	2026-02-21 12:30:00	f	f	t	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c40055	2026-03-06	2026-03-06 20:00:00	2026-03-06 17:30:00	2026-03-06 17:30:00	2026-03-06 20:00:00	f	f	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c50056	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c50057	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c50058	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c50059	2026-03-09	2026-03-09 20:00:00	2026-03-09 17:30:00	2026-03-09 17:30:00	2026-03-09 20:00:00	f	f	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c5005a	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c5005b	2026-03-25	2026-03-26 01:00:00	2026-03-25 22:00:00	2026-03-25 22:00:00	2026-03-26 01:00:00	f	t	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c5005c	2026-03-10	2026-03-10 20:00:00	2026-03-10 17:30:00	2026-03-10 17:30:00	2026-03-10 20:00:00	f	f	f	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c5005d	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c6005e	2026-03-11	2026-03-11 20:00:00	2026-03-11 17:30:00	2026-03-11 17:30:00	2026-03-11 20:00:00	f	f	f	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c6005f	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c60060	2026-03-12	2026-03-12 20:00:00	2026-03-12 17:30:00	2026-03-12 17:30:00	2026-03-12 20:00:00	f	f	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c60061	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c60062	2026-03-23	2026-03-24 01:00:00	2026-03-23 22:00:00	2026-03-23 22:00:00	2026-03-24 01:00:00	f	t	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c70063	2026-03-13	2026-03-13 20:00:00	2026-03-13 17:30:00	2026-03-13 17:30:00	2026-03-13 20:00:00	f	f	f	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c70064	2026-03-28	2026-03-28 12:30:00	2026-03-28 08:30:00	2026-03-28 08:30:00	2026-03-28 12:30:00	f	f	t	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c70065	2026-03-28	2026-03-28 12:30:00	2026-03-28 08:30:00	2026-03-28 08:30:00	2026-03-28 12:30:00	f	f	t	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c70066	2026-03-28	2026-03-28 12:30:00	2026-03-28 08:30:00	2026-03-28 08:30:00	2026-03-28 12:30:00	f	f	t	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c70067	2026-03-26	2026-03-27 01:00:00	2026-03-26 22:00:00	2026-03-26 22:00:00	2026-03-27 01:00:00	f	t	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c80068	2026-03-16	2026-03-16 20:00:00	2026-03-16 17:30:00	2026-03-16 17:30:00	2026-03-16 20:00:00	f	f	f	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c80069	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c8006a	2026-03-17	2026-03-17 20:00:00	2026-03-17 17:30:00	2026-03-17 17:30:00	2026-03-17 20:00:00	f	f	f	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c8006b	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c8006c	2026-03-06	2026-03-06 20:00:00	2026-03-06 17:30:00	2026-03-06 17:30:00	2026-03-06 20:00:00	f	f	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c8006d	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c8006e	2026-03-24	2026-03-25 01:00:00	2026-03-24 22:00:00	2026-03-24 22:00:00	2026-03-25 01:00:00	f	t	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c8006f	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c80070	2026-03-21	2026-03-21 12:30:00	2026-03-21 08:30:00	2026-03-21 08:30:00	2026-03-21 12:30:00	f	f	t	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c80071	2026-04-06	2026-04-06 20:00:00	2026-04-06 17:30:00	2026-04-06 17:30:00	2026-04-06 20:00:00	f	f	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c80072	2026-04-18	2026-04-18 12:30:00	2026-04-18 08:30:00	2026-04-18 08:30:00	2026-04-18 12:30:00	f	f	t	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c80073	2026-04-22	2026-04-23 01:00:00	2026-04-22 22:00:00	2026-04-22 22:00:00	2026-04-23 01:00:00	f	t	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490c90074	2026-04-07	2026-04-07 20:00:00	2026-04-07 17:30:00	2026-04-07 17:30:00	2026-04-07 20:00:00	f	f	f	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c90075	2026-04-18	2026-04-18 12:30:00	2026-04-18 08:30:00	2026-04-18 08:30:00	2026-04-18 12:30:00	f	f	t	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c90076	2026-04-08	2026-04-08 20:00:00	2026-04-08 17:30:00	2026-04-08 17:30:00	2026-04-08 20:00:00	f	f	f	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c90077	2026-04-18	2026-04-18 12:30:00	2026-04-18 08:30:00	2026-04-18 08:30:00	2026-04-18 12:30:00	f	f	t	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490c90078	2026-04-09	2026-04-09 20:00:00	2026-04-09 17:30:00	2026-04-09 17:30:00	2026-04-09 20:00:00	f	f	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490c90079	2026-04-18	2026-04-18 12:30:00	2026-04-18 08:30:00	2026-04-18 08:30:00	2026-04-18 12:30:00	f	f	t	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ca007a	2026-04-10	2026-04-10 20:00:00	2026-04-10 17:30:00	2026-04-10 17:30:00	2026-04-10 20:00:00	f	f	f	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490ca007b	2026-04-25	2026-04-25 12:30:00	2026-04-25 08:30:00	2026-04-25 08:30:00	2026-04-25 12:30:00	f	f	t	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ca007c	2026-04-25	2026-04-25 12:30:00	2026-04-25 08:30:00	2026-04-25 08:30:00	2026-04-25 12:30:00	f	f	t	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ca007d	2026-04-25	2026-04-25 12:30:00	2026-04-25 08:30:00	2026-04-25 08:30:00	2026-04-25 12:30:00	f	f	t	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ca007e	2026-04-23	2026-04-24 01:00:00	2026-04-23 22:00:00	2026-04-23 22:00:00	2026-04-24 01:00:00	f	t	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490ca007f	2026-04-13	2026-04-13 20:00:00	2026-04-13 17:30:00	2026-04-13 17:30:00	2026-04-13 20:00:00	f	f	f	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490cc0080	2026-04-25	2026-04-25 12:30:00	2026-04-25 08:30:00	2026-04-25 08:30:00	2026-04-25 12:30:00	f	f	t	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490cc0081	2026-04-14	2026-04-14 20:00:00	2026-04-14 17:30:00	2026-04-14 17:30:00	2026-04-14 20:00:00	f	f	f	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490cc0082	2026-04-25	2026-04-25 12:30:00	2026-04-25 08:30:00	2026-04-25 08:30:00	2026-04-25 12:30:00	f	f	t	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490cc0083	2026-04-15	2026-04-15 20:00:00	2026-04-15 17:30:00	2026-04-15 17:30:00	2026-04-15 20:00:00	f	f	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490cc0084	2026-04-25	2026-04-25 12:30:00	2026-04-25 08:30:00	2026-04-25 08:30:00	2026-04-25 12:30:00	f	f	t	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490cc0085	2026-04-16	2026-04-16 20:00:00	2026-04-16 17:30:00	2026-04-16 17:30:00	2026-04-16 20:00:00	f	f	f	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490cc0086	2026-04-18	2026-04-18 12:30:00	2026-04-18 08:30:00	2026-04-18 08:30:00	2026-04-18 12:30:00	f	f	t	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490cc0087	2026-04-17	2026-04-17 20:00:00	2026-04-17 17:30:00	2026-04-17 17:30:00	2026-04-17 20:00:00	f	f	f	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490cc0088	2026-04-18	2026-04-18 12:30:00	2026-04-18 08:30:00	2026-04-18 08:30:00	2026-04-18 12:30:00	f	f	t	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490cc0089	2026-04-06	2026-04-06 20:00:00	2026-04-06 17:30:00	2026-04-06 17:30:00	2026-04-06 20:00:00	f	f	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490cd008a	2026-04-18	2026-04-18 12:30:00	2026-04-18 08:30:00	2026-04-18 08:30:00	2026-04-18 12:30:00	f	f	t	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490cd008b	2026-04-24	2026-04-25 01:00:00	2026-04-24 22:00:00	2026-04-24 22:00:00	2026-04-25 01:00:00	f	t	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490cd008c	2026-04-07	2026-04-07 20:00:00	2026-04-07 17:30:00	2026-04-07 17:30:00	2026-04-07 20:00:00	f	f	f	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490cd008d	2026-04-18	2026-04-18 12:30:00	2026-04-18 08:30:00	2026-04-18 08:30:00	2026-04-18 12:30:00	f	f	t	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ce008e	2026-04-08	2026-04-08 20:00:00	2026-04-08 17:30:00	2026-04-08 17:30:00	2026-04-08 20:00:00	f	f	f	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490ce008f	2026-04-25	2026-04-25 12:30:00	2026-04-25 08:30:00	2026-04-25 08:30:00	2026-04-25 12:30:00	f	f	t	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ce0090	2026-05-06	2026-05-06 20:00:00	2026-05-06 17:30:00	2026-05-06 17:30:00	2026-05-06 20:00:00	f	f	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490ce0091	2026-05-16	2026-05-16 12:30:00	2026-05-16 08:30:00	2026-05-16 08:30:00	2026-05-16 12:30:00	f	f	t	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ce0092	2026-05-22	2026-05-23 01:00:00	2026-05-22 22:00:00	2026-05-22 22:00:00	2026-05-23 01:00:00	f	t	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490ce0093	2026-05-07	2026-05-07 20:00:00	2026-05-07 17:30:00	2026-05-07 17:30:00	2026-05-07 20:00:00	f	f	f	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490ce0094	2026-05-16	2026-05-16 12:30:00	2026-05-16 08:30:00	2026-05-16 08:30:00	2026-05-16 12:30:00	f	f	t	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ce0095	2026-05-08	2026-05-08 20:00:00	2026-05-08 17:30:00	2026-05-08 17:30:00	2026-05-08 20:00:00	f	f	f	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490ce0096	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ce0097	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ce0098	2026-05-25	2026-05-26 01:00:00	2026-05-25 22:00:00	2026-05-25 22:00:00	2026-05-26 01:00:00	f	t	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490ce0099	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490ce009a	2026-05-11	2026-05-11 20:00:00	2026-05-11 17:30:00	2026-05-11 17:30:00	2026-05-11 20:00:00	f	f	f	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d1009b	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d1009c	2026-05-12	2026-05-12 20:00:00	2026-05-12 17:30:00	2026-05-12 17:30:00	2026-05-12 20:00:00	f	f	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d1009d	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d1009e	2026-05-13	2026-05-13 20:00:00	2026-05-13 17:30:00	2026-05-13 17:30:00	2026-05-13 20:00:00	f	f	f	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d1009f	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d100a0	2026-05-14	2026-05-14 20:00:00	2026-05-14 17:30:00	2026-05-14 17:30:00	2026-05-14 20:00:00	f	f	f	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d100a1	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d100a2	2026-05-15	2026-05-15 20:00:00	2026-05-15 17:30:00	2026-05-15 17:30:00	2026-05-15 20:00:00	f	f	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d100a3	2026-05-30	2026-05-30 12:30:00	2026-05-30 08:30:00	2026-05-30 08:30:00	2026-05-30 12:30:00	f	f	t	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d400a4	2026-05-26	2026-05-27 01:00:00	2026-05-26 22:00:00	2026-05-26 22:00:00	2026-05-27 01:00:00	f	t	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d400a5	2026-05-16	2026-05-16 12:30:00	2026-05-16 08:30:00	2026-05-16 08:30:00	2026-05-16 12:30:00	f	f	t	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d500a6	2026-05-16	2026-05-16 12:30:00	2026-05-16 08:30:00	2026-05-16 08:30:00	2026-05-16 12:30:00	f	f	t	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d500a7	2026-05-06	2026-05-06 20:00:00	2026-05-06 17:30:00	2026-05-06 17:30:00	2026-05-06 20:00:00	f	f	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d500a8	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d500a9	2026-05-07	2026-05-07 20:00:00	2026-05-07 17:30:00	2026-05-07 17:30:00	2026-05-07 20:00:00	f	f	f	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d500aa	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d500ab	2026-05-08	2026-05-08 20:00:00	2026-05-08 17:30:00	2026-05-08 17:30:00	2026-05-08 20:00:00	f	f	f	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600ac	2026-05-23	2026-05-23 12:30:00	2026-05-23 08:30:00	2026-05-23 08:30:00	2026-05-23 12:30:00	f	f	t	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600ad	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600ae	2026-06-22	2026-06-23 01:00:00	2026-06-22 22:00:00	2026-06-22 22:00:00	2026-06-23 01:00:00	f	t	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d600af	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600b0	2026-06-08	2026-06-08 20:00:00	2026-06-08 17:30:00	2026-06-08 17:30:00	2026-06-08 20:00:00	f	f	f	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600b1	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600b2	2026-06-09	2026-06-09 20:00:00	2026-06-09 17:30:00	2026-06-09 17:30:00	2026-06-09 20:00:00	f	f	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600b3	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600b4	2026-06-25	2026-06-26 01:00:00	2026-06-25 22:00:00	2026-06-25 22:00:00	2026-06-26 01:00:00	f	t	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d600b5	2026-06-10	2026-06-10 20:00:00	2026-06-10 17:30:00	2026-06-10 17:30:00	2026-06-10 20:00:00	f	f	f	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600b6	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600b7	2026-06-11	2026-06-11 20:00:00	2026-06-11 17:30:00	2026-06-11 17:30:00	2026-06-11 20:00:00	f	f	f	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600b8	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600b9	2026-06-12	2026-06-12 20:00:00	2026-06-12 17:30:00	2026-06-12 17:30:00	2026-06-12 20:00:00	f	f	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600ba	2026-06-27	2026-06-27 12:30:00	2026-06-27 08:30:00	2026-06-27 08:30:00	2026-06-27 12:30:00	f	f	t	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600bb	2026-06-23	2026-06-24 01:00:00	2026-06-23 22:00:00	2026-06-23 22:00:00	2026-06-24 01:00:00	f	t	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d600bc	2026-06-27	2026-06-27 12:30:00	2026-06-27 08:30:00	2026-06-27 08:30:00	2026-06-27 12:30:00	f	f	t	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600bd	2026-06-27	2026-06-27 12:30:00	2026-06-27 08:30:00	2026-06-27 08:30:00	2026-06-27 12:30:00	f	f	t	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600be	2026-06-15	2026-06-15 20:00:00	2026-06-15 17:30:00	2026-06-15 17:30:00	2026-06-15 20:00:00	f	f	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600bf	2026-06-27	2026-06-27 12:30:00	2026-06-27 08:30:00	2026-06-27 08:30:00	2026-06-27 12:30:00	f	f	t	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600c0	2026-06-26	2026-06-27 01:00:00	2026-06-26 22:00:00	2026-06-26 22:00:00	2026-06-27 01:00:00	f	t	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d600c1	2026-06-16	2026-06-16 20:00:00	2026-06-16 17:30:00	2026-06-16 17:30:00	2026-06-16 20:00:00	f	f	f	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600c2	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600c3	2026-06-17	2026-06-17 20:00:00	2026-06-17 17:30:00	2026-06-17 17:30:00	2026-06-17 20:00:00	f	f	f	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600c4	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600c5	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600c6	2026-06-24	2026-06-25 01:00:00	2026-06-24 22:00:00	2026-06-24 22:00:00	2026-06-25 01:00:00	f	t	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d600c7	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600c8	2026-06-08	2026-06-08 20:00:00	2026-06-08 17:30:00	2026-06-08 17:30:00	2026-06-08 20:00:00	f	f	f	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600c9	2026-06-20	2026-06-20 12:30:00	2026-06-20 08:30:00	2026-06-20 08:30:00	2026-06-20 12:30:00	f	f	t	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600ca	2026-07-06	2026-07-06 20:00:00	2026-07-06 17:30:00	2026-07-06 17:30:00	2026-07-06 20:00:00	f	f	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d600cb	2026-07-18	2026-07-18 12:30:00	2026-07-18 08:30:00	2026-07-18 08:30:00	2026-07-18 12:30:00	f	f	t	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d600cc	2026-07-22	2026-07-23 01:00:00	2026-07-22 22:00:00	2026-07-22 22:00:00	2026-07-23 01:00:00	f	t	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d700cd	2026-07-07	2026-07-07 20:00:00	2026-07-07 17:30:00	2026-07-07 17:30:00	2026-07-07 20:00:00	f	f	f	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d700ce	2026-07-18	2026-07-18 12:30:00	2026-07-18 08:30:00	2026-07-18 08:30:00	2026-07-18 12:30:00	f	f	t	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d700cf	2026-07-08	2026-07-08 20:00:00	2026-07-08 17:30:00	2026-07-08 17:30:00	2026-07-08 20:00:00	f	f	f	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d700d0	2026-07-18	2026-07-18 12:30:00	2026-07-18 08:30:00	2026-07-18 08:30:00	2026-07-18 12:30:00	f	f	t	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d700d1	2026-07-09	2026-07-09 20:00:00	2026-07-09 17:30:00	2026-07-09 17:30:00	2026-07-09 20:00:00	f	f	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d700d2	2026-07-18	2026-07-18 12:30:00	2026-07-18 08:30:00	2026-07-18 08:30:00	2026-07-18 12:30:00	f	f	t	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d700d3	2026-07-10	2026-07-10 20:00:00	2026-07-10 17:30:00	2026-07-10 17:30:00	2026-07-10 20:00:00	f	f	f	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d700d4	2026-07-25	2026-07-25 12:30:00	2026-07-25 08:30:00	2026-07-25 08:30:00	2026-07-25 12:30:00	f	f	t	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d700d5	2026-07-25	2026-07-25 12:30:00	2026-07-25 08:30:00	2026-07-25 08:30:00	2026-07-25 12:30:00	f	f	t	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d700d6	2026-07-25	2026-07-25 12:30:00	2026-07-25 08:30:00	2026-07-25 08:30:00	2026-07-25 12:30:00	f	f	t	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d700d7	2026-07-23	2026-07-24 01:00:00	2026-07-23 22:00:00	2026-07-23 22:00:00	2026-07-24 01:00:00	f	t	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d700d8	2026-07-13	2026-07-13 20:00:00	2026-07-13 17:30:00	2026-07-13 17:30:00	2026-07-13 20:00:00	f	f	f	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d700d9	2026-07-25	2026-07-25 12:30:00	2026-07-25 08:30:00	2026-07-25 08:30:00	2026-07-25 12:30:00	f	f	t	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800da	2026-07-14	2026-07-14 20:00:00	2026-07-14 17:30:00	2026-07-14 17:30:00	2026-07-14 20:00:00	f	f	f	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d800db	2026-07-25	2026-07-25 12:30:00	2026-07-25 08:30:00	2026-07-25 08:30:00	2026-07-25 12:30:00	f	f	t	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800dc	2026-07-15	2026-07-15 20:00:00	2026-07-15 17:30:00	2026-07-15 17:30:00	2026-07-15 20:00:00	f	f	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d800dd	2026-07-25	2026-07-25 12:30:00	2026-07-25 08:30:00	2026-07-25 08:30:00	2026-07-25 12:30:00	f	f	t	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800de	2026-07-16	2026-07-16 20:00:00	2026-07-16 17:30:00	2026-07-16 17:30:00	2026-07-16 20:00:00	f	f	f	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d800df	2026-07-18	2026-07-18 12:30:00	2026-07-18 08:30:00	2026-07-18 08:30:00	2026-07-18 12:30:00	f	f	t	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800e0	2026-07-17	2026-07-17 20:00:00	2026-07-17 17:30:00	2026-07-17 17:30:00	2026-07-17 20:00:00	f	f	f	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d800e1	2026-07-18	2026-07-18 12:30:00	2026-07-18 08:30:00	2026-07-18 08:30:00	2026-07-18 12:30:00	f	f	t	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800e2	2026-07-06	2026-07-06 20:00:00	2026-07-06 17:30:00	2026-07-06 17:30:00	2026-07-06 20:00:00	f	f	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d800e3	2026-07-18	2026-07-18 12:30:00	2026-07-18 08:30:00	2026-07-18 08:30:00	2026-07-18 12:30:00	f	f	t	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800e4	2026-07-24	2026-07-25 01:00:00	2026-07-24 22:00:00	2026-07-24 22:00:00	2026-07-25 01:00:00	f	t	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d800e5	2026-07-07	2026-07-07 20:00:00	2026-07-07 17:30:00	2026-07-07 17:30:00	2026-07-07 20:00:00	f	f	f	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d800e6	2026-07-18	2026-07-18 12:30:00	2026-07-18 08:30:00	2026-07-18 08:30:00	2026-07-18 12:30:00	f	f	t	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800e7	2026-07-08	2026-07-08 20:00:00	2026-07-08 17:30:00	2026-07-08 17:30:00	2026-07-08 20:00:00	f	f	f	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d800e8	2026-07-25	2026-07-25 12:30:00	2026-07-25 08:30:00	2026-07-25 08:30:00	2026-07-25 12:30:00	f	f	t	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800e9	2026-08-06	2026-08-06 20:00:00	2026-08-06 17:30:00	2026-08-06 17:30:00	2026-08-06 20:00:00	f	f	f	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d800ea	2026-08-15	2026-08-15 12:30:00	2026-08-15 08:30:00	2026-08-15 08:30:00	2026-08-15 12:30:00	f	f	t	accepted	\N	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d800eb	2026-08-07	2026-08-07 20:00:00	2026-08-07 17:30:00	2026-08-07 17:30:00	2026-08-07 20:00:00	f	f	f	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d900ec	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d900ed	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d900ee	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d900ef	2026-08-25	2026-08-26 01:00:00	2026-08-25 22:00:00	2026-08-25 22:00:00	2026-08-26 01:00:00	f	t	f	accepted	\N	6b39462f-1134-4e9a-9a06-f2b3687940b7	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490d900f0	2026-08-10	2026-08-10 20:00:00	2026-08-10 17:30:00	2026-08-10 17:30:00	2026-08-10 20:00:00	f	f	f	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490d900f1	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490d900f2	2026-08-11	2026-08-11 20:00:00	2026-08-11 17:30:00	2026-08-11 17:30:00	2026-08-11 20:00:00	f	f	f	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490da00f3	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490da00f4	2026-08-12	2026-08-12 20:00:00	2026-08-12 17:30:00	2026-08-12 17:30:00	2026-08-12 20:00:00	f	f	f	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490da00f5	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490da00f6	2026-08-13	2026-08-13 20:00:00	2026-08-13 17:30:00	2026-08-13 17:30:00	2026-08-13 20:00:00	f	f	f	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490da00f7	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490da00f8	2026-08-14	2026-08-14 20:00:00	2026-08-14 17:30:00	2026-08-14 17:30:00	2026-08-14 20:00:00	f	f	f	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490da00f9	2026-08-29	2026-08-29 12:30:00	2026-08-29 08:30:00	2026-08-29 08:30:00	2026-08-29 12:30:00	f	f	t	accepted	\N	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490da00fa	2026-08-29	2026-08-29 12:30:00	2026-08-29 08:30:00	2026-08-29 08:30:00	2026-08-29 12:30:00	f	f	t	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490db00fb	2026-08-26	2026-08-27 01:00:00	2026-08-26 22:00:00	2026-08-26 22:00:00	2026-08-27 01:00:00	f	t	f	accepted	\N	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490db00fc	2026-08-15	2026-08-15 12:30:00	2026-08-15 08:30:00	2026-08-15 08:30:00	2026-08-15 12:30:00	f	f	t	accepted	\N	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490db00fd	2026-08-17	2026-08-17 20:00:00	2026-08-17 17:30:00	2026-08-17 17:30:00	2026-08-17 20:00:00	f	f	f	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490db00fe	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490dc00ff	2026-08-06	2026-08-06 20:00:00	2026-08-06 17:30:00	2026-08-06 17:30:00	2026-08-06 20:00:00	f	f	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490dd0100	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490dd0101	2026-08-24	2026-08-25 01:00:00	2026-08-24 22:00:00	2026-08-24 22:00:00	2026-08-25 01:00:00	f	t	f	accepted	\N	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố máy chủ ban đêm	\N
a9fea941-a089-1454-81a0-892490dd0102	2026-08-07	2026-08-07 20:00:00	2026-08-07 17:30:00	2026-08-07 17:30:00	2026-08-07 20:00:00	f	f	f	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Làm thêm giờ hoàn thành báo cáo tiến độ dự án	\N
a9fea941-a089-1454-81a0-892490dd0103	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
a9fea941-a089-1454-81a0-892490dd0104	2026-08-22	2026-08-22 12:30:00	2026-08-22 08:30:00	2026-08-22 08:30:00	2026-08-22 12:30:00	f	f	t	accepted	\N	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	Hỗ trợ bảo trì hệ thống và triển khai release cuối tuần	\N
\.


--
-- Data for Name: payrolls; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payrolls (payroll_id, user_id, timesheet_id, period_month, period_year, base_salary, hourly_rate, basic_pay, overtime_pay, allowance_pay, bonus_pay, gross_pay, insurance_deduction, tax_deduction, other_deduction, total_deduction, net_pay, status, note, calculated_at, approved_at, paid_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pending_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pending_users (id, birth_date, code, created_date, email, first_name, gender, last_name, password, pending_id, base_salary, citizen_id, contract_end_date, contract_start_date, contract_type, created_at, personal_email, phone_number, place_of_birth, rejection_reason, status, updated_at, created_by, department_id, job_id, shift_id) FROM stdin;
\.


--
-- Data for Name: post_hashtag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post_hashtag (post_id, hashtag_id) FROM stdin;
\.


--
-- Data for Name: post_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post_reactions (reaction_id, created_at, reaction, updated_at, interactable_id, user_id) FROM stdin;
\.


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posts (post_id, comment_count, created_at, media_urls, reaction_count, share_count, text, updatedd_at, visibility, interactable_id, user_id) FROM stdin;
\.


--
-- Data for Name: resignation_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resignation_requests (resignation_id, created_at, hr_approved_at, hr_comment, last_working_date, manager_approved_at, manager_comment, reason, status, submitted_time, updated_at, hr_or_executive_id, manager_id, user_id) FROM stdin;
a9fea941-a08a-1483-81a0-8a99a4310000	2026-09-10 16:15:20.002115	\N	\N	2026-11-01	\N	\N	móa cty tuất vãi cl	PENDING	2026-09-10 16:15:19.983117	2026-09-10 16:15:20.002115	\N	\N	cf26d867-49f1-4c12-b35b-c79bfb2884fc
a9fea941-a08a-141a-81a0-8aa86dbe0000	2026-09-10 16:31:29.09971	\N	\N	2026-11-01	\N	\N	Chuyển định hướng nghề nghiệp và phát triển năng lực cá nhân	CANCELLED	2026-09-10 16:31:29.084708	2026-09-10 16:31:33.010658	\N	\N	9fbc67a0-b671-479c-9b46-3076df068741
a9fea941-a08a-141a-81a0-8aa88a8c0001	2026-09-10 16:31:36.462283	\N	\N	2026-11-01	\N	\N	Chuyển định hướng nghề nghiệp và phát triển năng lực cá nhân	PENDING	2026-09-10 16:31:36.460282	2026-09-10 16:31:36.462283	\N	\N	9fbc67a0-b671-479c-9b46-3076df068741
\.


--
-- Data for Name: salaries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.salaries (salary_id, base_salary, end_date, is_active, pay_frequency, start_date, work_days, user_id) FROM stdin;
d1c8e2e9-dcd7-4bbd-8092-e0bda85868ad	65000000	\N	t	MONTHLY	2020-03-01	22	5934b552-2406-4a70-b69b-f0abec6bdd28
d3cb3a79-859c-45a2-b0cf-5bce7257beb2	50000000	\N	t	MONTHLY	2020-03-31	22	6b39462f-1134-4e9a-9a06-f2b3687940b7
7ee60cd6-bdd5-4d1e-bc1b-d572235f089c	30000000	\N	t	MONTHLY	2020-04-30	22	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa
039923c8-3a6f-484c-adf0-fa0df4c9b0cf	30000000	\N	t	MONTHLY	2020-05-30	22	c6322771-714d-4d31-a732-47f86ac8465e
47f23ade-50d9-46e3-b449-1ed2e7d439c3	30000000	\N	t	MONTHLY	2020-06-29	22	fca9aa46-b141-415f-ab4c-9f336bdfd46e
ab16063a-7f29-4d72-ba50-2ca2d66b8b9d	35000000	\N	t	MONTHLY	2020-07-29	22	a3214f8e-94d1-4f9e-80c7-bd66dd570a78
243d3baf-d340-4a22-b949-1d0866f9a3b8	28000000	\N	t	MONTHLY	2020-08-28	22	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1
9c3185ef-c3be-4ae3-a02b-ae50c356a76e	35000000	\N	t	MONTHLY	2020-09-27	22	cb0bf52b-924d-4a02-bcde-af3cb2a371ff
f4eab815-5eaf-40f0-a4f6-01ae4271a76b	15000000	\N	t	MONTHLY	2026-02-21	22	d1f7cf77-4784-4b35-8d12-f2833e3bb066
5a5873cd-f3df-4401-b5d6-fcb31db3052e	15000000	\N	t	MONTHLY	2026-03-23	22	951f937f-2724-4cf5-9b4f-7528f736d782
59fb4171-6c80-4693-a199-4f2806019c0a	15000000	\N	t	MONTHLY	2026-04-22	22	35337165-e0d0-4dd1-9c67-cc48180363af
69343ed8-a569-4bee-b576-80d471e81c12	15000000	\N	t	MONTHLY	2026-05-22	22	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd
d8adaed5-5e06-4271-8fee-93d4b6c30aa9	15000000	\N	t	MONTHLY	2026-06-21	22	9fbc67a0-b671-479c-9b46-3076df068741
7bc4edcb-abfa-45b9-ae46-b37cb3cd28f0	15000000	\N	t	MONTHLY	2026-07-21	22	cf26d867-49f1-4c12-b35b-c79bfb2884fc
e8f39c75-e671-4ea0-9ab1-e5d66964e3b7	195000000	\N	t	MONTHLY	2026-10-01	22	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff
\.


--
-- Data for Name: shares; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shares (share_id, comment_count, created_at, reaction_count, text_content, visibility, interactable_id, post_id, user_id) FROM stdin;
\.


--
-- Data for Name: user_bank_accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_bank_accounts (user_id, bank_account_number, bank_name) FROM stdin;
5934b552-2406-4a70-b69b-f0abec6bdd28	ACC00000002	Vietcombank
6b39462f-1134-4e9a-9a06-f2b3687940b7	ACC00000003	Techcombank
ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	ACC00000004	Techcombank
c6322771-714d-4d31-a732-47f86ac8465e	ACC00000005	ACB
fca9aa46-b141-415f-ab4c-9f336bdfd46e	ACC00000006	ACB
a3214f8e-94d1-4f9e-80c7-bd66dd570a78	ACC00000007	BIDV
1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	ACC00000008	BIDV
cb0bf52b-924d-4a02-bcde-af3cb2a371ff	ACC00000009	BIDV
d1f7cf77-4784-4b35-8d12-f2833e3bb066	VCB00000021	Vietcombank
951f937f-2724-4cf5-9b4f-7528f736d782	VCB00000022	Vietcombank
35337165-e0d0-4dd1-9c67-cc48180363af	VCB00000023	Vietcombank
1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	VCB00000024	Vietcombank
9fbc67a0-b671-479c-9b46-3076df068741	VCB00000025	Vietcombank
cf26d867-49f1-4c12-b35b-c79bfb2884fc	VCB00000026	Vietcombank
1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	774995215	VCB - Chi nhánh Bến Thành
\.


--
-- Data for Name: user_contracts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_contracts (user_id, contract_end_date, contract_start_date, contract_type, contract_id) FROM stdin;
5934b552-2406-4a70-b69b-f0abec6bdd28	\N	2020-03-01	Indefinite	8b0cd135-32fe-42f8-b0b3-d9e8a529a62c
6b39462f-1134-4e9a-9a06-f2b3687940b7	\N	2020-03-31	Indefinite	2446b2be-16ec-48ad-8cb2-7c92271a28b7
ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	\N	2020-04-30	Indefinite	3520fad0-98d6-4daf-8aeb-ad4fe0ef3f78
c6322771-714d-4d31-a732-47f86ac8465e	\N	2020-05-30	Indefinite	6248c13f-c1e5-4735-872a-1b99e7729219
fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N	2020-06-29	Indefinite	39db5e77-1708-488f-a9d6-1b83d298a93d
a3214f8e-94d1-4f9e-80c7-bd66dd570a78	\N	2020-07-29	Indefinite	8c982565-c3b1-44ba-906d-426b1c901654
1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	\N	2020-08-28	Indefinite	9ead9e03-a80e-47f8-8d6a-72216191983a
cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N	2020-09-27	Indefinite	3c76715b-58f5-4364-8372-48857fac928d
d1f7cf77-4784-4b35-8d12-f2833e3bb066	2027-02-21	2026-02-21	Fixed-term	62bab603-2f6e-4d37-af1b-15794cbf0c61
951f937f-2724-4cf5-9b4f-7528f736d782	2027-03-23	2026-03-23	Fixed-term	506d495a-b2bf-481b-b7a4-751ae982bb2e
35337165-e0d0-4dd1-9c67-cc48180363af	2027-04-22	2026-04-22	Fixed-term	d40d308b-a5c1-4ff8-b788-429ff96f328e
1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2027-05-22	2026-05-22	Fixed-term	7f8200d4-3fff-4b8e-893c-35733fed2f01
9fbc67a0-b671-479c-9b46-3076df068741	2027-06-21	2026-06-21	Fixed-term	85d5f6ab-1fe0-4e8b-9743-c4010db94dab
cf26d867-49f1-4c12-b35b-c79bfb2884fc	2027-07-21	2026-07-21	Fixed-term	ca7965f3-6112-4f5e-af92-bcf5932b9527
1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	2029-10-01	2026-10-01	Fixed-term	3066b231-26a4-42e4-9892-6b00ee50c910
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_profiles (user_id, citizen_id_number, emergency_contact_name, emergency_contact_phone, marital_status, nationality, personal_email, phone_number, place_of_birth, social_insurance_number, social_insurance_start_date, tax_identification_number) FROM stdin;
5934b552-2406-4a70-b69b-f0abec6bdd28	001000000002	Emergency Contact	0912345679	Married	Vietnamese	lethanhhuong@personal.com	0912345678	Hanoi	SI00002	2015-03-02	TAX00002
6b39462f-1134-4e9a-9a06-f2b3687940b7	001000000003	Emergency Contact	0912345679	Married	Vietnamese	phamhoangnam@personal.com	0912345678	Hanoi	SI00003	2015-04-01	TAX00003
ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	001000000004	Emergency Contact	0912345679	Married	Vietnamese	tranvanan@personal.com	0912345678	Danang	SI00004	2015-05-01	TAX00004
c6322771-714d-4d31-a732-47f86ac8465e	001000000005	Emergency Contact	0912345679	Married	Vietnamese	lethibinh@personal.com	0912345678	Danang	SI00005	2015-05-31	TAX00005
fca9aa46-b141-415f-ab4c-9f336bdfd46e	001000000006	Emergency Contact	0912345679	Married	Vietnamese	phamthicuc@personal.com	0912345678	Ho Chi Minh	SI00006	2015-06-30	TAX00006
a3214f8e-94d1-4f9e-80c7-bd66dd570a78	001000000007	Emergency Contact	0912345679	Married	Vietnamese	nguyenvandung@personal.com	0912345678	Ho Chi Minh	SI00007	2015-07-30	TAX00007
1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	001000000008	Emergency Contact	0912345679	Married	Vietnamese	hoangthiha@personal.com	0912345678	Haiphong	SI00008	2015-08-29	TAX00008
cb0bf52b-924d-4a02-bcde-af3cb2a371ff	001000000009	Emergency Contact	0912345679	Married	Vietnamese	dovanhung@personal.com	0912345678	Haiphong	SI00009	2015-09-28	TAX00009
d1f7cf77-4784-4b35-8d12-f2833e3bb066	001000000021	Emergency Contact	0912345679	Married	Vietnamese	sales.employee@personal.com	0912345678	Hà Nội	SI00021	2021-09-22	TAX00021
951f937f-2724-4cf5-9b4f-7528f736d782	001000000022	Emergency Contact	0912345679	Married	Vietnamese	marketing.employee@personal.com	0912345678	Đà Nẵng	SI00022	2021-10-22	TAX00022
35337165-e0d0-4dd1-9c67-cc48180363af	001000000023	Emergency Contact	0912345679	Married	Vietnamese	hr.employee@personal.com	0912345678	Hồ Chí Minh	SI00023	2021-11-21	TAX00023
1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	001000000024	Emergency Contact	0912345679	Married	Vietnamese	finance.employee@personal.com	0912345678	Hà Nội	SI00024	2021-12-21	TAX00024
9fbc67a0-b671-479c-9b46-3076df068741	001000000025	Emergency Contact	0912345679	Married	Vietnamese	support.employee@personal.com	0912345678	Đà Nẵng	SI00025	2022-01-20	TAX00025
cf26d867-49f1-4c12-b35b-c79bfb2884fc	001000000026	Emergency Contact	0912345679	Married	Vietnamese	it.employee@personal.com	0912345678	Hồ Chí Minh	SI00026	2022-02-19	TAX00026
1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	079204021490	Lê Vương Thủy	0785890216	Độc thân	Việt Nam	tuanphan1999@gmail.com	0389195180	TP.HCM	7956789012	2026-08-01	079204021490
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_sessions (session_id, created_at, device_id, meta_data, revoked, token, user_id, last_active_at) FROM stdin;
556853a5-8528-41e8-88da-778138eb2ec1	2026-09-03 00:00:00	2f067dc5-2b88-47ca-860f-56faa13546b7	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	phWKTSBw2m6F0BRvC8QiK2kMjmSVklAq+MP/ZXk51tQ=	d1f7cf77-4784-4b35-8d12-f2833e3bb066	\N
312721ea-5a69-4432-89cf-289e35c8972c	2026-09-03 00:00:00	166f0301-13ae-4b09-9295-b58fe0dca21f	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	d6Fw+UfF29WvgsWl7ruGeb+HfySiO04nwQuijmsSmc4=	35337165-e0d0-4dd1-9c67-cc48180363af	\N
9c4bac0e-f186-4ad2-bf4b-1c1a1abca4ce	2026-09-04 00:00:00	4c72631c-9ebb-45f3-bc87-2f3a285b2976	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	pJ+jeLhlFL7BvDKy4RlM+Wmx1suSOhO2DSBCSvNIqEo=	35337165-e0d0-4dd1-9c67-cc48180363af	\N
a8ce6819-13dd-4dca-80c7-3ff149c58a6f	2026-09-04 00:00:00	f1a76248-307e-4aad-99dc-4bf9d3b1310f	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	A6wSHoV3KwyuMYFw0lDBvxmh1nk0BWj9tsEtFoIC408=	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	\N
a9c081a9-8c07-4966-ab28-f41653c4f3aa	2026-09-04 00:00:00	473794d9-026d-431a-81c2-0450b89772a0	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	Yu0JsKXoDFrFChzMxeu41TAYiylmIZEolsvYT4s/lmo=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
85c230a9-91bd-49f6-95a9-946fd24a9878	2026-09-03 00:00:00	05f29bc3-de1c-47f2-8c0d-e1e724b36c53	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	t	9SSSWQT0RmDmgTkkRz8+oe+8U+ZML214tAP4fpwULEA=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
2e213188-22e1-4fd1-a45e-705978d1f298	2026-09-08 00:00:00	1d1ca6c9-4ad7-40e9-ae41-8bc4135f353f	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	K/khmS/EPQtPrWWOBWxMyu2fiSRHeTf3CN4cVavbB44=	d1f7cf77-4784-4b35-8d12-f2833e3bb066	\N
8722db5e-1d93-47c4-acfb-1e2aa238611a	2026-09-03 00:00:00	e1e068ef-0909-4f74-80c1-6f0a611458b0	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	pPQdoudhrlZhb1T7p/GkMeYgmJQFS+xbSB0tZTNu6oo=	d1f7cf77-4784-4b35-8d12-f2833e3bb066	\N
64a13f13-6c06-4ee7-9316-b3e877f4b156	2026-09-08 00:00:00	2e915303-7241-4438-b1f1-f2705c5bc01e	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	XkXjlHbcBvA9vMNvy7E+44qdhZvY07fslhOz5dwD8Zs=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
33fc1d2b-af12-49aa-b9ef-7f63a76705a9	2026-09-08 00:00:00	e9a5bc74-13d5-4022-a846-684266b1f376	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	VEdyhbQZWI1kDPpQ/gQVeSv5NCTTim/u5RAs65EBN6s=	35337165-e0d0-4dd1-9c67-cc48180363af	\N
dac26bdd-e28a-4c5b-b3b7-1e50722e64c3	2026-09-08 00:00:00	29211c49-182e-4521-86a7-9dd22bfce15b	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	JA6sTLPvrIlzBpptjrba9qi9Str1RBLojf0b90V3oFg=	d1f7cf77-4784-4b35-8d12-f2833e3bb066	\N
45c9cfc5-640f-4947-8c0c-a006be0a29ab	2026-09-08 00:00:00	65a0fbb4-d4bf-4e3b-ba9a-f0696fccc039	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	G8rxhU6wNB3XOBSmxCjM8mdo/jbUxrQ2OQSYJefFjj8=	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	\N
5777acc0-bdd5-49a4-a28f-17b78da23fa2	2026-09-08 00:00:00	78f620d9-db04-40f1-8470-098e04ef2322	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	EQICcYOGVMZRUUqCgPEKnDqW+99baBbHUNPWVvQIvMk=	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	\N
bc7763ca-a1dc-4761-b657-5f7ff249ff46	2026-09-08 00:00:00	123de968-2c59-483f-a5c3-5df0b95b12fe	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	1D2rfBJEvBM1LDt5XsUc0Rwv5RNFrgDwByJCYM3ujko=	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	\N
f94513fd-cb9e-4e7f-9cc2-679da6e27691	2026-09-08 00:00:00	0ce7f8c3-7a7b-408d-9e99-230e694281e2	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	bt3R7KpfLjrnpQ1fsxwNhboktnv/GCvHMKJwJ3p85SU=	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	\N
51ca72ed-6bed-4b91-8506-e143847f1923	2026-09-08 00:00:00	87e5d05c-608e-4cf7-9b0c-ea6039ece0e0	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	KEhmLHVvEDdznqKIlggUUeFvM0SL6MJ2W1rdxm8/YmQ=	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	\N
312a949b-2c24-4655-b357-8245a8f93073	2026-09-09 00:00:00	dfe5c966-05ed-4e7c-b1e7-1d5c481e2382	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-urllib", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	2bReBGZt7H0bgJyuo2tHySz5xPHvo19Y99rIqRVwx08=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
b419cb95-6fc1-42e0-afc7-adac282c1be2	2026-09-09 00:00:00	e20a7776-acae-4116-9554-5724e87b3785	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	jf1IrH26vgC1WwK6/9L8iRlDORa/cBy7KlVzUT7w4cA=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
a3c1baaa-c1a2-49a6-b8a1-40cb83b16a5d	2026-09-09 00:00:00	d54e859c-a233-4e05-8093-0ffff83f6a1c	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	3dniKX14UEZoubbmxxTFSQijRv8O7amvtuYy9CCZ8BM=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
58a62c70-59e7-4311-8ab1-3466e92414ce	2026-09-09 00:00:00	2c55b8e0-044f-466c-95c2-fa67afb3183c	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	NbV5O5+dtrMkyCcVYJgbWBAhIcHE7ce1B1332Aut5vQ=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
6158c239-c982-4120-ac87-65937d69d287	2026-09-09 00:00:00	b1b29693-3754-46f3-aa8a-76b3d7f0d2a3	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	rlqQU+jvXRVwqOJ6wmYsMkIlbU1+iFwhvOHPuOOJkqQ=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
296a2353-6d19-40df-a868-f61bd47679b7	2026-09-09 00:00:00	277037e1-55a1-46be-8989-7a4c072fb11c	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	9Y3cWYI520l3LChVeM1nLVd9SaLJPkbWDgqU+7N0aVA=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
368a7769-5ab3-4f1c-97c8-e51483157653	2026-09-09 00:00:00	60a2a209-8f59-48b1-8356-a145e16b5649	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	wzD9U4Hd74USqhxsKGgB6wX4iNbJJRUyQ2YX+5KFhVA=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
b1b98fa9-b902-43ec-a43b-7faab1fb6875	2026-09-09 00:00:00	5dd3d8e5-9a80-4210-a0d6-12a3e24f6d85	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	NHtkT6E5wPtZjEKJJrkmIvJDCjtiLa6/oNM3YPre5SQ=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
190cacf3-dd94-45b7-81d6-a3c29380b939	2026-09-09 00:00:00	079c2b54-91a2-4cfd-a39a-56e4c50dfed1	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	C2ZanaNrA+4d1Kc+tMH6isM5hG/KlUte9+qq2AXJ85k=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
ecde9eb3-423e-4aba-82a7-e192683eb2fb	2026-09-09 00:00:00	772f3efc-cf09-414a-af8c-dbc1dacc0520	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	vPHLcL0tp4xU7HGH4ULIUjlvXQ8JlQt/sE/dVJvhx+o=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
8ef42bc3-7d91-4a4f-8e3e-560de8e8a904	2026-09-04 00:00:00	d1c219dc-a5a4-45eb-ad59-4e44155da021	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	t	VfWWYQvOVDO1u/nFA0lXHTHoOZ8kulxUS07MzS7mI3o=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
a8aade09-6420-490f-8f27-c4441172e38d	2026-09-09 00:00:00	f4a12e61-69a2-4b9d-b1eb-6573990a5b50	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	+2twZOxgGERVBRTZQygQOpbNkJpWLEnMuqurrY2APxs=	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	\N
a4702122-f07a-41fb-bb85-f547dc3828dc	2026-09-09 00:00:00	fbd04c25-4df6-46a6-8530-7f775171fb4f	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	EtRiLGzZcsz1IGu/enFBYiP/D4eaJC8QuGDnY8D3edM=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
12b2e94d-d951-488a-a197-dd5b16bd0850	2026-09-10 00:00:00	aeee2079-65f5-4c8a-9ea6-aec060d9fb0c	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	OsQHay0L9YbuCAvrsaSjNF1RTiAyzWllgtpQkhlwKDQ=	9fbc67a0-b671-479c-9b46-3076df068741	\N
2ad3aee9-b929-427c-98d1-adc97217bf06	2026-09-09 00:00:00	8c8ca970-3959-47ed-861c-dd5376da1cb5	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	ZKndn+MWPL5yMSyt+vj7QNdumOU0WaxcLPq3oxqvuZ4=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
de2053d3-3dd5-41f9-a938-2066a8ab338a	2026-09-09 00:00:00	e950ec68-0536-4a47-a38e-73c6750940ad	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Netscape", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown"}	f	B1G8axWL1ju0u87a+8kCeiXE32KdCxKO7RK/6Umzsx0=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
3883237c-4ffd-4b1a-9e20-2b796a6926c7	2026-09-09 00:00:00	02bbc222-2698-46a3-aa29-79bb2ec623e4	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	t	b1CpdYXM9S22CaGsMqiNfyhP3QzNPGEH7ElUklgKUWE=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
26ace1a7-7dce-411d-bd4d-0077c5675d95	2026-09-09 00:00:00	a1d44f42-9d98-4bd3-892f-b8e928fb2012	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	vfBd2Yv7iSyXfRS48+m7bVgqOd+QshdcXMt811NvyuA=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
f3ab378b-68c9-4814-9509-a4fa23db18f8	2026-09-09 00:00:00	2375d703-8180-4d96-a320-bdd6ced88e8a	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop"}	f	6zHybNaD0l+Sj3+928paezDSxHTmWL4aTWM40SE3WYo=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
246a2902-2d27-4d5a-994b-39073ff515bc	2026-09-10 00:00:00	12d9a9b3-f231-4e92-afb9-e0c470f0c960	{"city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot"}	f	qnnEsiHpr3cmNaf0MX4nzCXZUNa6Wfz9pEyBwxJ8dkM=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, annual_leave_days, birth_date, email, first_name, gender, joined_date, last_name, password, profile_pic_url, used_leave_days, department_id, job_id, face_embedding, employee_code, shift_id, is_active) FROM stdin;
35337165-e0d0-4dd1-9c67-cc48180363af	12	1988-07-10	hr.employee@company.com	Lê	Male	2024-07-01	Văn C	$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa		1	0190abcd-4567-7def-89ab-cdef0123456a	0190abcd-a000-7def-89ab-cdef0123457f	\N	EMP023	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
5934b552-2406-4a70-b69b-f0abec6bdd28	12	1975-08-20	lethanhhuong@company.com	Lê	Female	2026-08-20	Thị Thanh Hương	$2a$10$o6vPM5zo0YPKsZrsH.1GT./MRKG3.69smS4yft5.hr/wRTWqCTQ8e		0	0190abcd-7890-7def-89ab-cdef0123456d	1ee9735c-667d-4216-8c29-8845d3d8fe2c	[-0.0706182,-0.02440524,0.051300026,-0.07044039,-0.07500896,-0.0063882475,-0.1037836,-0.0636454,0.09720149,-0.11637047,0.29258674,-0.022610668,-0.20904659,-0.118493006,-0.0038452572,0.101710685,-0.14950617,-0.086384796,-0.03133555,0.02915993,0.060975574,-0.022434775,-0.0019274172,0.04525204,-0.15706751,-0.40429807,-0.138573,-0.08157271,-0.058432154,-0.09844958,-0.08635497,0.07241908,-0.15699525,0.0023992173,-0.007216729,0.12818065,-0.04564044,-0.021077635,0.08415219,0.03940196,-0.19034645,0.014436534,0.011578114,0.22961453,0.24686642,0.055579398,0.04573247,-0.07088264,0.08072381,-0.2015723,0.033435583,0.12912072,0.09542255,0.061544575,0.030369014,-0.101832084,0.014387749,0.12141425,-0.106824204,0.058770694,0.006691239,-0.12931743,0.0077365553,-0.012207013,0.2113108,0.062429752,-0.15159014,-0.15416513,0.064853996,-0.17388168,-0.07766111,0.08831308,-0.17547353,-0.24313813,-0.32903543,0.066873275,0.4080887,0.12610516,-0.22237317,0.024839407,-0.06976482,-0.037709586,0.14441326,0.13743745,0.0108737685,0.0005504964,-0.17754292,0.012937761,0.2443223,-0.068917304,0.0033393046,0.22153589,-0.031526744,0.11292885,0.040710744,0.04773336,-0.075748235,0.029795662,-0.100801714,-0.027917303,0.010469684,-0.053934373,-0.039550714,0.07108806,-0.09952997,0.12549263,3.8082246e-05,0.0060343277,0.022267615,-0.04030912,-0.11925396,-0.109427825,0.11704346,-0.2745144,0.11607515,0.21060447,0.12944634,0.14113411,0.118921824,0.06686463,-0.038803533,-0.031436518,-0.16521482,0.031047808,0.039083432,0.016450834,0.048745114,-0.048677053]	EMP002	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
fca9aa46-b141-415f-ab4c-9f336bdfd46e	12	1982-11-02	phamthicuc@company.com	Phạm	Female	2026-08-20	Thị Cúc	$2a$10$ZJbAWr7h0DaEJpW0GSfIReY9bBCRimMvEOAWeFSms9.gIEwwK6.Z6		0	0190abcd-4567-7def-89ab-cdef0123456a	5946cfbd-ad20-419d-bae6-cfe09a261c77	\N	EMP006	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
6b39462f-1134-4e9a-9a06-f2b3687940b7	12	1978-02-14	phamhoangnam@company.com	Phạm	Male	2026-08-20	Hoàng Nam	$2a$10$lUtr13N4ZKF8qVJQNNGRFuQ4t5xNg1rqoWvi6vEu8ulGD3mDK0dIy		0	0190abcd-7890-7def-89ab-cdef0123456d	cbe3513b-8a01-49aa-bb63-0fc0056360ae	\N	EMP003	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	12	1975-06-15	tranvanan@company.com	Trần	Male	2026-08-20	Văn An	$2a$10$apGI3btyg7m2o0NoatwzVeCfyCylUkU6UAPV5yYOVSZ8mH0o29VCq		0	0190abcd-2345-7def-89ab-cdef01234568	893213d9-3245-4382-9b84-f2e82415706b	\N	EMP004	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
c6322771-714d-4d31-a732-47f86ac8465e	12	1978-09-20	lethibinh@company.com	Lê	Female	2026-08-20	Thị Bình	$2a$10$W6Y1nGpD372zoDsfoR.2../dfCPf.s/1HWOBKDG9WQhHilr0sZx/G		0	0190abcd-3456-7def-89ab-cdef01234569	f83436ed-9621-4ec5-b1c4-ac55aa5de01c	\N	EMP005	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
a3214f8e-94d1-4f9e-80c7-bd66dd570a78	12	1973-07-30	nguyenvandung@company.com	Nguyễn	Male	2026-08-20	Văn Dũng	$2a$10$tKV1Oppv5QcAoJzlBiv4NuIuJbtYQkbPL2ze2ZwP3HoCL4rygheZy		0	0190abcd-5678-7def-89ab-cdef0123456b	3f6dd18d-9644-4413-8f4b-c4c6f5b8da93	\N	EMP007	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	12	1980-03-25	hoangthiha@company.com	Hoàng	Female	2026-08-20	Thị Hà	$2a$10$Maf7aZNqZrG23AXVf4sezOtyWeRpUKBAp3rtu3PZerAj5bl3sT3TS		0	0190abcd-6789-7def-89ab-cdef0123456c	edcaa4eb-52fb-436c-87b7-6f6d411a72b8	\N	EMP008	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
cb0bf52b-924d-4a02-bcde-af3cb2a371ff	12	1976-12-12	dovanhung@company.com	Đỗ	Male	2026-08-20	Văn Hùng	$2a$10$t9qiJgn3XRkucz4RmWAJoOxYb/MzCSj1umn2qSaSY0r0kFmJNgTXG		0	0190abcd-1234-7def-89ab-cdef01234567	8f18e557-3fd7-4393-9c28-2d9c29e613ca	\N	EMP009	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
d1f7cf77-4784-4b35-8d12-f2833e3bb066	12	1990-01-15	sales.employee@company.com	Nguyễn	Male	2024-06-01	Văn A	$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa		0	0190abcd-2345-7def-89ab-cdef01234568	0190abcd-8000-7def-89ab-cdef01234575	\N	EMP021	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
951f937f-2724-4cf5-9b4f-7528f736d782	12	1992-03-20	marketing.employee@company.com	Trần	Female	2024-06-15	Thị B	$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa		0	0190abcd-3456-7def-89ab-cdef01234569	0190abcd-9000-7def-89ab-cdef0123457a	\N	EMP022	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	12	1991-11-05	finance.employee@company.com	Phạm	Female	2024-07-15	Thị D	$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa		0	0190abcd-5678-7def-89ab-cdef0123456b	0190abcd-b000-7def-89ab-cdef01234584	\N	EMP024	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
9fbc67a0-b671-479c-9b46-3076df068741	12	1989-09-25	support.employee@company.com	Hoàng	Male	2024-08-01	Văn E	$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa		0	0190abcd-6789-7def-89ab-cdef0123456c	0190abcd-c000-7def-89ab-cdef01234589	\N	EMP025	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
cf26d867-49f1-4c12-b35b-c79bfb2884fc	12	1993-12-12	it.employee@company.com	Đỗ	Female	2024-08-15	Thị F	$2a$10$Bt0lKdC.9pT73LrcoC7nIut/Q.Jf0tleVqERetTmnFHqVAP4dOvQa		0	0190abcd-1234-7def-89ab-cdef01234567	0190abcd-7000-7def-89ab-cdef0123456d	\N	EMP026	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	12	2004-08-14	nguyenminhduc@company.com	Hoàng	Nam	2026-08-20	Lê Minh Trung	$2a$10$tLvorPcENdJACfDzMtDOROIUmoujYYBngfP.OXy2XGm34frZIQqW6	/uploads/avatars/93eeb475-5acc-433b-8032-dd6d302d112d.webp	0	0190abcd-7890-7def-89ab-cdef0123456d	584a3e62-c23b-4925-93a6-208ca87e068e	[-0.10619169,0.084548436,0.066045314,0.016829323,-0.093992755,-0.018793397,-0.043872394,-0.21016113,0.12352578,-0.10384144,0.2556409,-0.06241406,-0.18526869,-0.15330496,-0.0353977,0.20238957,-0.12705497,-0.14674178,-0.069980845,-0.022015743,0.026622372,-0.042635836,0.05603297,0.06920933,-0.09702276,-0.35008663,-0.10961397,-0.086113915,-0.016839635,-0.07287155,-0.08335102,0.09441249,-0.2262931,-0.020945301,-0.039964415,0.10099664,-0.037690915,-0.07338695,0.17311388,-0.0389892,-0.19109572,-0.041405257,0.03253486,0.17420317,0.19381803,0.0309595,0.048412714,-0.06838818,0.031029504,-0.13978843,0.05773215,0.1277563,0.047688328,0.06003608,-0.08328276,-0.17518637,-0.014741531,0.054116495,-0.10312985,0.0071776193,0.086150914,-0.16667384,-0.13547012,-0.03182113,0.27165338,0.17281945,-0.09066216,-0.17251578,0.15517609,-0.16886522,-0.0625281,-0.01618588,-0.19096264,-0.18379802,-0.34069726,0.06564736,0.36068198,0.09090418,-0.1849247,0.04976602,-0.037148826,0.0655646,0.09101144,0.17222047,-0.04485344,0.071615405,-0.10339195,0.039500203,0.17382105,-0.054993603,-0.048204977,0.25207138,-0.038520876,0.06165527,0.039843474,-0.019166596,0.057451136,0.036210798,-0.10263221,0.045646716,0.09630408,-0.023274984,0.009234368,0.073523924,-0.10243351,0.0677551,-0.012133532,0.07409682,0.04812538,-0.044437435,-0.16801693,-0.11789357,0.15626271,-0.19849461,0.20211469,0.17161456,0.06350903,0.14791948,0.17422035,0.18383321,0.030738238,-0.013313028,-0.20282179,0.038746484,0.16240126,-0.0249238,0.07262002,0.06656713]	EMP001	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
\.


--
-- Data for Name: work_shift_schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_shift_schedules (schedule_id, day_of_week, end_time, is_working, rest_end_time, rest_start_time, start_time, shift_id) FROM stdin;
3854c093-a3d1-49f5-999a-2ae55ad23393	1	17:30:00	t	13:30:00	12:00:00	08:00:00	52a5e36a-8fc5-4142-8d20-0a2436ab59a3
13db492c-8561-4088-9114-bf04ad39d9e1	2	17:30:00	t	13:30:00	12:00:00	08:00:00	52a5e36a-8fc5-4142-8d20-0a2436ab59a3
938c77dd-2f2d-4cd8-9259-96a4e5ca4b7f	3	17:30:00	t	13:30:00	12:00:00	08:00:00	52a5e36a-8fc5-4142-8d20-0a2436ab59a3
2a92678c-4aa9-4335-acb6-949d75d6e003	4	17:30:00	t	13:30:00	12:00:00	08:00:00	52a5e36a-8fc5-4142-8d20-0a2436ab59a3
205b0003-430c-46da-bf3a-16584bbaf588	5	17:30:00	t	13:30:00	12:00:00	08:00:00	52a5e36a-8fc5-4142-8d20-0a2436ab59a3
9ed7bc3f-3ff3-4aa9-98f9-1e2f0ffa779a	6	00:00:00	f	\N	\N	00:00:00	52a5e36a-8fc5-4142-8d20-0a2436ab59a3
408cfd4f-34eb-4a0d-9c67-21380647a210	7	00:00:00	f	\N	\N	00:00:00	52a5e36a-8fc5-4142-8d20-0a2436ab59a3
\.


--
-- Data for Name: work_shifts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_shifts (shift_id, name) FROM stdin;
52a5e36a-8fc5-4142-8d20-0a2436ab59a3	Gi? h…nh ch¡nh (T2-T6)
\.


--
-- Name: employee_number_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_number_seq', 20, true);


--
-- Name: attendances attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_pkey PRIMARY KEY (attendance_id);


--
-- Name: comment_reactions comment_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT comment_reactions_pkey PRIMARY KEY (reaction_id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (comment_id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- Name: hashtags hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hashtags
    ADD CONSTRAINT hashtags_pkey PRIMARY KEY (hashtag_id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (holiday_id);


--
-- Name: interactables interactables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactables
    ADD CONSTRAINT interactables_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (job_id);


--
-- Name: leave_requests leave_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_pkey PRIMARY KEY (request_id);


--
-- Name: monthly_payroll_summaries monthly_payroll_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_payroll_summaries
    ADD CONSTRAINT monthly_payroll_summaries_pkey PRIMARY KEY (summary_id);


--
-- Name: monthly_timesheets monthly_timesheets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_timesheets
    ADD CONSTRAINT monthly_timesheets_pkey PRIMARY KEY (timesheet_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: overtime_records overtime_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overtime_records
    ADD CONSTRAINT overtime_records_pkey PRIMARY KEY (overtime_record_id);


--
-- Name: payrolls payrolls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payrolls
    ADD CONSTRAINT payrolls_pkey PRIMARY KEY (payroll_id);


--
-- Name: pending_users pending_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT pending_users_pkey PRIMARY KEY (id);


--
-- Name: post_hashtag post_hashtag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_hashtag
    ADD CONSTRAINT post_hashtag_pkey PRIMARY KEY (post_id, hashtag_id);


--
-- Name: post_reactions post_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT post_reactions_pkey PRIMARY KEY (reaction_id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (post_id);


--
-- Name: resignation_requests resignation_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resignation_requests
    ADD CONSTRAINT resignation_requests_pkey PRIMARY KEY (resignation_id);


--
-- Name: salaries salaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salaries
    ADD CONSTRAINT salaries_pkey PRIMARY KEY (salary_id);


--
-- Name: shares shares_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shares
    ADD CONSTRAINT shares_pkey PRIMARY KEY (share_id);


--
-- Name: shares uk2k4r5i519t9un4a33nhrd8wcq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shares
    ADD CONSTRAINT uk2k4r5i519t9un4a33nhrd8wcq UNIQUE (interactable_id);


--
-- Name: salaries uk65x0hr7lif8m6c15yanah3jwn; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salaries
    ADD CONSTRAINT uk65x0hr7lif8m6c15yanah3jwn UNIQUE (user_id);


--
-- Name: users uk6dotkott2kjsp8vw4d0m25fb7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk6dotkott2kjsp8vw4d0m25fb7 UNIQUE (email);


--
-- Name: attendances uk_attendance_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT uk_attendance_user UNIQUE (user_id, work_date);


--
-- Name: payrolls uk_payroll_user_period; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payrolls
    ADD CONSTRAINT uk_payroll_user_period UNIQUE (user_id, period_month, period_year);


--
-- Name: overtime_records uk_requestorid_overtimedate; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overtime_records
    ADD CONSTRAINT uk_requestorid_overtimedate UNIQUE (requestor_id, approved_date);


--
-- Name: monthly_payroll_summaries uk_summary_period; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_payroll_summaries
    ADD CONSTRAINT uk_summary_period UNIQUE (period_month, period_year);


--
-- Name: monthly_timesheets uk_timesheet_user_period; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_timesheets
    ADD CONSTRAINT uk_timesheet_user_period UNIQUE (user_id, period_month, period_year);


--
-- Name: comment_reactions uk_user_comment; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT uk_user_comment UNIQUE (user_id, comment_id);


--
-- Name: post_reactions uk_user_interactable; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT uk_user_interactable UNIQUE (user_id, interactable_id);


--
-- Name: users uk_users_employee_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk_users_employee_code UNIQUE (employee_code);


--
-- Name: work_shift_schedules ukfecbt4avyonl61jsb39qu6r49; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_shift_schedules
    ADD CONSTRAINT ukfecbt4avyonl61jsb39qu6r49 UNIQUE (shift_id, day_of_week);


--
-- Name: posts ukgqtx4dgdihntkxf46k2yr37l9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT ukgqtx4dgdihntkxf46k2yr37l9 UNIQUE (interactable_id);


--
-- Name: hashtags ukn5hdv9cb9wan3f73y432jsfs5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hashtags
    ADD CONSTRAINT ukn5hdv9cb9wan3f73y432jsfs5 UNIQUE (hashtag_name);


--
-- Name: user_bank_accounts user_bank_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_bank_accounts
    ADD CONSTRAINT user_bank_accounts_pkey PRIMARY KEY (user_id);


--
-- Name: user_contracts user_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contracts
    ADD CONSTRAINT user_contracts_pkey PRIMARY KEY (contract_id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (session_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: work_shift_schedules work_shift_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_shift_schedules
    ADD CONSTRAINT work_shift_schedules_pkey PRIMARY KEY (schedule_id);


--
-- Name: work_shifts work_shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_shifts
    ADD CONSTRAINT work_shifts_pkey PRIMARY KEY (shift_id);


--
-- Name: idx_payrolls_period; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payrolls_period ON public.payrolls USING btree (period_year, period_month);


--
-- Name: idx_timesheets_period; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timesheets_period ON public.monthly_timesheets USING btree (period_year, period_month);


--
-- Name: uk_user_work_date_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uk_user_work_date_active ON public.attendances USING btree (user_id, work_date) WHERE (is_deleted = false);


--
-- Name: attendances attendances_edited_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_edited_by_fkey FOREIGN KEY (edited_by) REFERENCES public.users(user_id);


--
-- Name: notifications fk13vcnq3ukas06ho1yrbc5lrb5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk13vcnq3ukas06ho1yrbc5lrb5 FOREIGN KEY (sender_id) REFERENCES public.users(user_id);


--
-- Name: post_hashtag fk1s7rl5hr86w67e87q2onyhuk5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_hashtag
    ADD CONSTRAINT fk1s7rl5hr86w67e87q2onyhuk5 FOREIGN KEY (post_id) REFERENCES public.posts(post_id);


--
-- Name: attendances fk_attendance_shift; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT fk_attendance_shift FOREIGN KEY (shift_id) REFERENCES public.work_shifts(shift_id);


--
-- Name: attendances fk_attendance_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT fk_attendance_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: comments fk_comment_interatable; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_comment_interatable FOREIGN KEY (interactable_id) REFERENCES public.interactables(id);


--
-- Name: comment_reactions fk_comment_reaction_comment; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT fk_comment_reaction_comment FOREIGN KEY (comment_id) REFERENCES public.comments(comment_id);


--
-- Name: comment_reactions fk_comment_reaction_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT fk_comment_reaction_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: comments fk_comment_reply; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_comment_reply FOREIGN KEY (parent_comment_id) REFERENCES public.comments(comment_id);


--
-- Name: comments fk_comment_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_comment_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: jobs fk_job_department; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT fk_job_department FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: leave_requests fk_leave_request_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT fk_leave_request_user FOREIGN KEY (approver_id) REFERENCES public.users(user_id);


--
-- Name: overtime_records fk_overtime_approver; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overtime_records
    ADD CONSTRAINT fk_overtime_approver FOREIGN KEY (approver_id) REFERENCES public.users(user_id);


--
-- Name: overtime_records fk_overtime_requestor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overtime_records
    ADD CONSTRAINT fk_overtime_requestor FOREIGN KEY (requestor_id) REFERENCES public.users(user_id);


--
-- Name: payrolls fk_payroll_timesheet; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payrolls
    ADD CONSTRAINT fk_payroll_timesheet FOREIGN KEY (timesheet_id) REFERENCES public.monthly_timesheets(timesheet_id) ON DELETE RESTRICT;


--
-- Name: payrolls fk_payroll_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payrolls
    ADD CONSTRAINT fk_payroll_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: posts fk_post_interactable; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_post_interactable FOREIGN KEY (interactable_id) REFERENCES public.interactables(id);


--
-- Name: post_reactions fk_post_reaction_interatable; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT fk_post_reaction_interatable FOREIGN KEY (interactable_id) REFERENCES public.interactables(id);


--
-- Name: post_reactions fk_post_reaction_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT fk_post_reaction_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: posts fk_post_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT fk_post_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: resignation_requests fk_resignation_hr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resignation_requests
    ADD CONSTRAINT fk_resignation_hr FOREIGN KEY (hr_or_executive_id) REFERENCES public.users(user_id);


--
-- Name: resignation_requests fk_resignation_manager; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resignation_requests
    ADD CONSTRAINT fk_resignation_manager FOREIGN KEY (manager_id) REFERENCES public.users(user_id);


--
-- Name: resignation_requests fk_resignation_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resignation_requests
    ADD CONSTRAINT fk_resignation_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: salaries fk_salary_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salaries
    ADD CONSTRAINT fk_salary_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: shares fk_share_interactable; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shares
    ADD CONSTRAINT fk_share_interactable FOREIGN KEY (interactable_id) REFERENCES public.interactables(id);


--
-- Name: shares fk_share_post; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shares
    ADD CONSTRAINT fk_share_post FOREIGN KEY (post_id) REFERENCES public.posts(post_id);


--
-- Name: shares fk_share_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shares
    ADD CONSTRAINT fk_share_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: work_shift_schedules fk_shift_schedules; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_shift_schedules
    ADD CONSTRAINT fk_shift_schedules FOREIGN KEY (shift_id) REFERENCES public.work_shifts(shift_id);


--
-- Name: monthly_timesheets fk_timesheet_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_timesheets
    ADD CONSTRAINT fk_timesheet_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: users fk_user_department; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_user_department FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: users fk_user_job; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_user_job FOREIGN KEY (job_id) REFERENCES public.jobs(job_id);


--
-- Name: users fk_user_shift; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_user_shift FOREIGN KEY (shift_id) REFERENCES public.work_shifts(shift_id);


--
-- Name: pending_users fka977e2fmof68djr6k2hv4vkw3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT fka977e2fmof68djr6k2hv4vkw3 FOREIGN KEY (job_id) REFERENCES public.jobs(job_id);


--
-- Name: user_contracts fkaax71dyljd3ogi797b9ufe1pr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contracts
    ADD CONSTRAINT fkaax71dyljd3ogi797b9ufe1pr FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: pending_users fkcgwebbk4l8sgrt830kxu5l560; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT fkcgwebbk4l8sgrt830kxu5l560 FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: pending_users fke0haxpxkek7d0hmpalb1ic3fm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT fke0haxpxkek7d0hmpalb1ic3fm FOREIGN KEY (shift_id) REFERENCES public.work_shifts(shift_id);


--
-- Name: post_hashtag fkg88dg5qwj3jcy1xglpqxpiqj5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_hashtag
    ADD CONSTRAINT fkg88dg5qwj3jcy1xglpqxpiqj5 FOREIGN KEY (hashtag_id) REFERENCES public.hashtags(hashtag_id);


--
-- Name: user_profiles fkjcad5nfve11khsnpwj1mv8frj; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT fkjcad5nfve11khsnpwj1mv8frj FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: user_bank_accounts fkndnjcihxy2pntu4qa16briv1q; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_bank_accounts
    ADD CONSTRAINT fkndnjcihxy2pntu4qa16briv1q FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: notifications fknlu738lvwn7496o5c8647u97g; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fknlu738lvwn7496o5c8647u97g FOREIGN KEY (recipent_id) REFERENCES public.users(user_id);


--
-- Name: pending_users fksi3e9jmeynhxqi3d40b1tox3f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT fksi3e9jmeynhxqi3d40b1tox3f FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict pGmcjJPPX2YW85Hxf7iQn8aYce7yJTiMKllHiXZtsnIyzT6Li2J2EV71OOSH5XF

