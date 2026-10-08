--
-- PostgreSQL database dump
--

\restrict iMPEBINDtocfzMur5h6ynnaLdQHrl7QXA0tt7q2bRjK0zPQyTAIbrpc67ZfgJxM

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

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
    pending_id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    gender character varying(255) NOT NULL,
    birth_date date NOT NULL,
    personal_email character varying(255) NOT NULL,
    phone_number character varying(255),
    citizen_id character varying(255),
    place_of_birth character varying(255),
    department_id uuid NOT NULL,
    job_id uuid NOT NULL,
    shift_id uuid,
    base_salary numeric(38,2),
    contract_type character varying(255),
    contract_start_date date,
    contract_end_date date,
    status character varying(255) DEFAULT 'PENDING'::character varying NOT NULL,
    rejection_reason character varying(255),
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_pending_users_contract_type CHECK (((contract_type)::text = ANY (ARRAY[('Indefinite'::character varying)::text, ('Fixed-term'::character varying)::text, ('Probation'::character varying)::text])))
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
    contract_id uuid DEFAULT gen_random_uuid() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_user_contracts_type CHECK (((contract_type)::text = ANY (ARRAY[('Indefinite'::character varying)::text, ('Fixed-term'::character varying)::text, ('Probation'::character varying)::text])))
);


ALTER TABLE public.user_contracts OWNER TO postgres;

--
-- Name: user_permission_grants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_permission_grants (
    permission character varying(40) NOT NULL,
    user_id uuid NOT NULL,
    granted_at timestamp(6) without time zone NOT NULL,
    granted_by uuid NOT NULL,
    CONSTRAINT user_permission_grants_permission_check CHECK (((permission)::text = ANY (ARRAY['ATTENDANCE_VIEW_ALL'::text, 'LEAVE_VIEW_ALL'::text, 'OVERTIME_VIEW_ALL'::text, 'PAYROLL_VIEW_ALL'::text, 'RESIGN_VIEW_ALL'::text, 'LEAVE_APPROVE'::text, 'OVERTIME_APPROVE'::text, 'RESIGN_APPROVE'::text, 'TIMESHEET_LOCK'::text, 'PAYROLL_MANAGE'::text, 'ACCOUNT_LOCK'::text, 'PERMISSION_GRANT'::text, 'ORG_MANAGE'::text, 'EMPLOYEE_VIEW_ALL'::text, 'EMPLOYEE_EDIT'::text])))
);


ALTER TABLE public.user_permission_grants OWNER TO postgres;

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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    device_id uuid NOT NULL,
    meta_data jsonb NOT NULL,
    revoked boolean DEFAULT false NOT NULL,
    token text NOT NULL,
    user_id uuid NOT NULL,
    last_active_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
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
a5516c65-7935-47f3-9cb3-3a6081263925	07:52:18	17:31:14	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c046fdb6-e4fd-4dc6-9705-7422ef06fb83	07:49:44	17:44:04	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
8130dfdf-7b6e-4b41-a521-67dd031c5161	07:59:16	17:50:37	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
82839f7a-1163-4471-a265-96c0cfc087d2	07:59:12	17:43:07	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
def97ae1-8ed1-4afd-a2f4-c65e1a75524d	07:55:09	17:38:52	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2a7757eb-d180-4442-b9ed-c9063ed15c27	07:45:10	17:39:38	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
bc03f674-acc4-4b04-b556-02ba862770f0	07:54:58	17:39:28	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
c5cc4653-ae27-4693-b30c-32afc5d29581	07:56:19	17:42:17	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
05ccb325-7042-4c3b-8051-fba22e462c66	07:52:28	17:32:38	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9d6cbe87-957e-4f45-b24c-be41f9c7f5af	07:51:47	17:40:38	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e016d1eb-df33-45b9-94d3-b09d68ffe7de	07:46:14	17:48:37	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f95d9fc6-dbf3-4740-9a9e-bc6459b4b1f2	08:29:43	17:38:36	LATE	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
671d6bb9-9d27-4c1a-8f41-c0d5c330ae7b	07:57:11	17:45:33	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
cce9d1c7-0373-4c4b-8c23-658920d03198	07:59:17	17:35:37	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
1bf9092f-acaf-42b3-9fb2-822f762651d1	07:58:31	17:32:30	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
d1273169-9284-44f7-8b75-c26ce00804c0	07:50:20	17:33:54	SUFFICIENT	2026-01-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
dc4abbfd-f00b-41fb-bd44-f2e4e0e838f6	07:51:44	17:45:18	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
0b7dc5d4-a8cc-4166-a77e-ff8430894423	07:51:52	17:47:02	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
e8bc2b04-ebac-4e2c-a3d7-986f27527fc1	07:50:16	17:40:07	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
86e02e52-efaa-424d-990f-758bfc1a8b34	07:54:55	17:00:42	EARLY	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
73f2189d-7b8b-4700-88d6-3aebcaf52f1b	07:52:26	17:31:12	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ac77931d-7dec-4ab6-80ae-bcba29feede9	07:54:48	17:45:40	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
352b16a6-353b-4e03-aa2a-b5c95c6b2036	07:45:13	17:38:35	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
6ad99cd1-23d8-4456-b661-ffdb0a9ade94	07:49:28	17:45:07	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
54b55694-e960-4538-9d15-632857e80d9e	07:55:38	17:37:45	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
20d6eb6f-37b3-4c49-a8a5-af3bc2a254bc	07:53:00	17:47:26	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
cb7a86c7-5877-4caf-a776-0c695c1836e2	07:58:58	17:33:29	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
795ec5a9-3557-46d9-a1de-78eed73a1f52	08:25:53	17:34:31	LATE	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
11d4b7ab-ebc8-4c90-a20d-1b658212b156	08:14:32	17:38:26	LATE	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
bf4c3c92-f2d2-43cd-9ac0-fe264de41651	07:52:15	17:44:35	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e6c73d4a-84df-4059-b1b3-b8df0ad14253	07:48:58	17:49:32	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
92658e60-2fde-47f9-b9d0-c56866886378	07:47:55	17:32:17	SUFFICIENT	2026-01-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
362b0e9a-8624-47c4-938a-578b78e5785d	07:58:26	17:40:59	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b601a84b-5eb5-482e-b1d8-569322a7a5fb	07:49:52	17:30:18	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a35347a5-bbb2-4224-b52b-03da5fcfd85d	07:58:37	17:48:42	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
c45582e3-f270-4a8d-adec-b52125a8c721	07:47:28	17:47:30	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b8462ec3-abb3-4ca0-9c72-13c0de59c881	07:53:48	17:47:24	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7f1a991f-92cc-4757-acb3-d906c5ae8353	07:50:55	17:36:44	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
7ebe7b62-efdc-43ad-8a21-5c206cc5a4da	07:51:14	17:43:02	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ac5af405-a024-492d-adcf-bfcf4e3516d8	07:52:45	17:42:24	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
765118b0-4bea-4fed-992d-57f0023433f4	07:58:09	17:15:02	EARLY	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
eb7d25e5-28c6-4410-8bec-7f16da071f39	07:54:21	17:33:55	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
cf0af52b-8b72-4755-9cbb-acbdf7cef26f	07:46:33	17:44:00	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
10022b58-9e86-4dce-8fbf-57f76ea930fa	07:51:55	17:50:09	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
4377e3a3-f17a-4796-a8ed-cfb5cec16050	07:57:16	17:40:39	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
07750d9b-4ce2-47a0-a09f-7776026a56cb	07:55:05	17:40:54	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
2d888fde-b7f1-4c92-972e-f27f9da18672	07:53:24	17:40:40	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f2cd8bb4-c0cf-4db6-a679-e8193824dc16	07:57:31	17:47:02	SUFFICIENT	2026-01-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c6e2bd32-2404-4b11-882d-57bbf41eaa41	07:48:40	17:39:14	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b4c61ffd-8ffb-4211-b0ff-8420ca93a99f	07:51:06	17:50:45	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
56363003-90e7-420e-ada0-fd610ecb2c0d	07:52:10	17:39:57	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
52cdc718-b571-40dd-8d8c-0f39804da8e8	07:50:50	17:31:18	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
d119a785-04b3-446f-989f-3d2237dc77a0	07:51:09	17:37:33	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
5ae1cd1b-2f16-4d3d-98db-e1e92e7d410d	07:55:50	17:35:10	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
1ca982d0-e144-4778-9662-7c3bcc0785e3	07:54:55	17:42:39	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
e441b3c8-30a0-4c61-99fa-52e8d890faf3	07:52:58	17:48:09	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
3cb37dcb-a7be-4098-846f-33a995df9938	07:55:16	17:44:16	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
2397a59b-61e8-4dff-b9da-89bbcd7d897a	07:59:51	17:44:57	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
57c9ea6c-11e5-4fed-a08c-b08592ed8e2a	07:53:10	17:32:28	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f4a182c3-3435-434b-bb56-475c11e49f6e	08:23:19	17:43:44	LATE	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b0de1642-9d0b-450f-9fd1-28349770d02d	07:58:19	17:36:24	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
2bf81402-f546-4985-92b3-3faf88414320	07:46:15	17:42:36	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b9295edf-eefa-4a9e-8377-ac7dc1ec84db	07:49:44	17:39:01	SUFFICIENT	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
0d2bb606-32aa-4280-82ab-b103ccbd1c5f	07:58:25	17:08:00	EARLY	2026-01-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
2b3dcc8b-8bad-43e3-8f26-d365cdc34744	07:55:49	17:31:58	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a223eae7-4b80-4cb5-809d-81bbdfd10948	07:52:53	17:39:49	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b70ac23f-4097-499a-8bb3-b1227fcf4a8f	07:54:51	17:41:14	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
cd39f95a-56aa-4bfa-840f-84c8ead511df	07:54:16	17:34:40	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e997b242-b35b-426e-bbf5-741fb5c7ee4e	07:55:41	17:31:19	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
accb141a-d454-4aee-b339-5f63a0518d27	07:45:37	17:41:46	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
c0a18275-9888-491a-a66a-57b2f0787390	07:59:18	17:40:47	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
7f03f830-25c3-4c29-86c3-2c93d775f95a	07:48:08	17:47:56	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
16942410-f461-4de3-9489-4413403d05ab	07:56:32	17:08:53	EARLY	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
ccef02c3-042e-4829-973f-b0868f03ba16	07:59:52	17:45:51	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
8fc7888b-c781-412c-a787-bf444176be67	07:58:21	17:33:29	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
36a3efc0-f037-45c8-a930-46dc2bce16ff	07:50:48	17:07:55	EARLY	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
9b1a873c-ac11-4401-9dd9-139644df27e7	07:55:25	17:47:23	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
5d88d60b-ffe5-458d-9a42-579a3a2f53db	07:51:00	17:38:34	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
3aabd98d-5a5f-4d7e-ba23-13dde1beb91b	07:50:43	17:38:37	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
007adba5-7434-4a6d-8c84-e9f692594b52	07:55:23	17:33:43	SUFFICIENT	2026-01-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
b8400851-968a-4454-858f-3b6057944b8e	07:45:39	17:47:20	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
089c7600-d06a-4248-9b37-95e9747d4c69	08:12:41	17:32:40	LATE	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
caea14e1-975d-4c43-98d1-c5104844d7aa	07:59:44	17:39:41	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
5f431ac2-6f0d-4c6f-9e66-2346e1a98279	07:47:02	17:31:19	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
fdbfa9e3-ec19-4143-b49b-b79f946765d0	08:08:06	17:12:56	LATE_AND_EARLY	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
06d732a1-1e17-4a60-94b4-a3e6046674bf	07:51:29	17:41:42	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
2c4aabde-46c4-4129-8cef-6224e22d43c9	08:27:34	17:43:37	LATE	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
e40ccf86-0bb9-4e85-8315-cb6647271a12	07:47:56	17:43:41	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
e7921384-4f90-41b1-8557-bc2921a35a76	07:52:39	17:43:17	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c5d8e9b8-ddf2-4237-a124-552da4ca8407	07:50:13	17:44:28	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d34b39ec-a2ec-4ee4-8081-c31438012071	08:32:23	17:33:43	LATE	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
592f8b54-7fad-4f58-98e7-5fbe8348569c	07:59:41	17:41:03	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3931c788-36d6-4c45-9043-d0a02f2aacb2	07:48:07	17:44:05	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
73992fbf-8f86-470e-90ec-bada413ad8c4	07:55:40	17:49:01	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
8d1a0b0c-ea08-446c-9998-11a3a8c9969e	07:50:15	17:34:50	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
72f8ac1f-808d-42ad-8dd5-7623c0eecb46	07:46:53	17:47:13	SUFFICIENT	2026-01-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
273c66ef-7db2-45a8-883b-ea8952b4ddd9	07:58:55	17:37:21	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
13be44a7-5379-49a7-88e5-c0dca8753fbf	07:57:57	17:49:00	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
76bc8d21-02cd-4c74-86c6-41d519c74c4b	07:47:08	17:47:16	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
980e27b9-d387-4afd-8167-239c1c7047e1	07:46:42	17:30:08	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ad135a89-f482-4d5d-8d03-3925f25095ed	07:57:50	17:37:37	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b3cd66d2-632a-4c5f-97bf-b735191dbf77	07:47:16	17:31:08	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
30d460e8-08b4-4abd-ade5-edc0dc836b46	07:53:07	17:32:30	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
aee1ca20-62b4-40ca-b681-22dcaf0ef39b	07:50:32	17:48:06	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
80983518-ceea-4388-9139-e40494f3f256	07:48:39	17:31:46	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
69b987cb-48ef-4d3e-b024-d200de342f94	07:58:42	17:46:19	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
1bc32101-2976-4937-9301-8d9fff1bfc53	07:45:03	17:45:54	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
472af245-dd06-4705-9f5e-8da04c657905	07:55:06	17:45:45	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
4811677f-fe12-455e-ad8a-84eaf7fe0375	08:07:57	17:32:20	LATE	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
1bd77e12-d1df-4d4e-b3b0-38b5d6557a8e	07:46:08	17:38:39	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
8efe8224-ba7e-4513-8d8b-6daa9bad732c	07:53:45	17:40:24	SUFFICIENT	2026-01-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
b192523e-18b6-486d-ac7b-60e1e45ff63c	08:14:29	17:18:06	LATE_AND_EARLY	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a601c492-ddd7-4b5c-8ad7-229ef7193707	07:46:54	17:50:41	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
95abb4cd-f590-4164-a57c-9a2911a080fa	07:53:46	17:36:27	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
429352ff-bac4-4e00-b39d-7570ae4a0e36	07:48:26	17:40:52	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
b8e33313-e303-4b13-b1ba-e769330e2fdb	07:51:46	17:33:20	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
962bc4d1-6cfd-47cc-b3b6-94d3206655e7	07:55:16	17:41:09	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
713d3cf8-f04e-4448-91b3-c74cb83b1fb6	07:52:04	17:32:53	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
7fc8739c-fc3d-46a2-aee8-6d448f9ba6e6	07:51:06	17:41:51	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
cb879e39-d45d-4abd-8048-b001d02a4053	07:45:37	17:47:35	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d059fe9a-57b3-472c-a86b-ca13ac9f4695	07:46:26	17:41:55	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
db7a4e1d-6ed3-44ba-bf84-50996de03296	07:57:27	17:31:18	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3be3b375-d63a-4b9e-9320-1530e5343faf	07:50:06	17:48:32	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
9e693121-0116-487e-bf85-6cf9bc8f01ad	07:55:30	17:37:54	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
1a9dd326-a38c-4116-8672-c2392de76dfa	07:58:35	17:41:07	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3647d8f8-2415-44ac-81f6-51730e42adca	07:54:14	17:43:54	SUFFICIENT	2026-01-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a74b6082-a876-47d2-8c3d-93f6fcd1e5dc	07:57:52	17:49:39	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
6d599d3f-8c63-432d-910a-99fb7913eb5a	07:53:01	17:49:59	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
afc41d6f-05a1-47c9-bb26-ca8e6cfa1c12	07:56:17	17:30:11	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
55cf79ec-78ea-4e2f-a9ab-804f705346a9	07:57:19	17:40:22	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
64639353-5cdd-45d2-b5dd-e2a3e22da35b	07:58:09	17:48:42	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d7fe1d02-a7d6-42c4-9dd4-e89bc855ae0c	07:47:47	17:50:01	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
0748a4cc-ea49-4284-a9e1-a51883ddcbc7	07:53:13	17:42:26	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
2483d18e-4ca3-4d97-ab1d-6fdbf79d6eed	07:47:23	17:39:46	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
479e09f5-ff8d-4766-9263-bfe9730bdd3f	07:54:38	17:32:56	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b166a33e-5cb2-4efb-99a4-e42467166a7f	07:47:48	17:49:03	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ec966bb6-62c1-4f10-aeba-16038447154c	07:49:28	17:43:31	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2c984d36-6100-435f-96d0-2053e5fe893a	07:51:17	17:36:48	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
c7bdf05f-aec0-49e5-9bfe-deb77faaaeed	07:50:27	17:33:18	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
4a3ccbb5-f5f1-4e12-9c8d-e8517a0e48cd	07:54:31	17:46:42	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
2f19d93d-9a4c-4123-938b-e0f6d5d3e770	07:48:25	17:49:03	SUFFICIENT	2026-01-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c28415e8-d9a5-4ccf-af40-0a10d25cf5e9	07:49:13	17:34:48	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
9481d243-4e13-4805-8832-4656358a1437	07:50:07	17:30:31	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9ee6b49e-2f4c-4c22-848f-2f111c5162e8	07:47:08	17:42:34	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
ec03230d-ee99-426b-b6cc-3241d88c1552	07:53:35	17:41:04	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b7894917-0941-4cf3-88cf-822bea132bc1	07:56:02	17:43:01	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e9efb893-bbaa-47bf-8d93-484042f680d1	07:46:55	17:40:36	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a2c60440-d527-4d3b-8cea-ba71d0c3a6a8	07:51:45	17:50:26	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
96b5954d-f073-468a-9016-554e9a9db1e9	07:51:01	17:40:10	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
9f810623-894e-47db-8e47-dc937347481c	07:54:29	17:41:05	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
670ad94b-df8d-4118-9553-1680c22df5bd	07:46:15	17:43:37	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
858ce3a5-6e90-40b8-8475-619ad81fbb02	07:46:25	17:39:47	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
fddbbf23-4f0d-40af-946a-acd26f028bc2	07:50:49	17:35:04	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
eb7e186e-308e-4925-88db-f524f6304243	07:46:33	17:46:12	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a47fb2ad-ac72-4bb3-b2e1-9ac0d751ad41	08:16:22	17:34:15	LATE	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
750e6c65-1ff4-4c3b-820a-238b2eef2321	07:49:12	17:35:38	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
74de9f2b-8e45-4e82-858e-cd24ae95b874	07:57:41	17:32:11	SUFFICIENT	2026-01-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
151a6c4f-f953-4ff2-ab9f-70d4c2bb503e	08:25:31	17:44:48	LATE	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
47b83879-f20e-4934-a8a9-b4df696f2bd4	07:54:28	17:48:41	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
5f612312-e4d6-4c32-8fa8-f1d39b43e91f	07:54:20	17:50:20	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
9d2f1aea-8cdd-4566-990e-74cc4d97d2eb	07:46:30	17:44:40	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
da2258ce-3c1a-470a-adf4-dce83d9a7972	07:49:37	17:31:22	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2cb8e6f7-dc6a-4744-ba91-a3785cd07514	07:49:29	17:44:02	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ed3c8eb1-a2a1-468f-9a7f-2a420b276d58	07:58:18	17:32:41	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ea3ffbea-4c9d-4357-8739-ed88d9253865	07:58:05	17:49:38	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
11229de4-8c4f-4a6d-9b84-ff0b8a155394	07:52:37	17:47:50	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
540ba590-f6ab-4723-8098-503607d7a340	07:45:28	17:48:41	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ab699fae-514a-4b67-83ff-8734c34f0154	07:54:30	17:46:09	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
1262fc52-8b80-485c-a544-bed7c21f5d89	08:19:06	17:40:45	LATE	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
77b2359b-de7e-4e38-aeab-5e9462681d92	07:55:11	17:31:15	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
dc25986a-eb7b-4e8d-8fe0-03b190b9576f	07:52:33	17:46:39	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
cd7056f6-5e01-4ad7-b450-20457befcc34	07:50:58	17:39:24	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
fdc592a2-d887-4aa6-a6ad-2f34e696ff19	07:50:43	17:49:03	SUFFICIENT	2026-01-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
e51480f1-8214-4ecb-b9b7-fc282c7c76be	07:55:21	17:32:21	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
415fa4d2-9ee4-45c3-be31-5c6041d84f7c	07:55:24	17:39:16	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
34cea982-e8c9-4616-9742-c855a7f70eb2	07:55:58	17:49:55	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
669621dd-1e31-4d9a-b7ca-d26676c2136d	07:46:37	17:34:58	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
ab93109c-44ee-4889-a82c-cc98d5956566	07:55:44	17:42:08	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ebf84404-58c2-4260-8dea-931259e091ac	07:46:19	17:47:24	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
34716459-5513-40e6-b535-092307825290	07:50:52	17:34:42	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
19036b19-6ffc-4a98-ba46-ba32998c7562	07:56:43	17:46:05	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
33761be6-8f29-461b-a839-c0c3d251fbe8	07:51:32	17:41:01	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
593c66f9-d260-4b07-8f17-3fc09b4a216d	07:47:13	17:40:49	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
4beeabb6-2f2c-4a60-9197-ead507dcf729	07:48:08	17:34:04	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
34e4d0bb-2970-4b3e-99cc-0e101efe6b87	07:57:06	17:46:49	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
2cacc2cf-e139-4b66-adcf-91671e24b4cb	07:56:56	17:46:02	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
92c1926b-d338-4be8-af6c-8c98782b46aa	07:59:49	17:49:08	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f5ccf9bc-9648-4e63-b375-4b99cde2063f	07:47:10	17:35:53	SUFFICIENT	2026-01-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c3181ee0-399a-4aa7-9447-000ff38e55da	07:54:51	17:35:46	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
757b801d-a5e7-4ac7-b96e-456f40f2dc61	07:51:23	17:37:28	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
297e415c-5a9f-4d85-bbd4-276fe4813c14	07:57:47	17:44:14	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
5c7f1198-15ff-4041-be27-3a12cf3d1f0a	07:49:51	17:45:57	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b9a30ea6-3ccf-4f5d-a24c-9c8614f7bb87	07:50:43	17:48:28	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
261c292a-1f89-4e63-86e6-d3400783c024	07:49:49	17:42:32	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
111b4c5e-6465-417e-b734-6561620b357b	07:47:52	17:36:51	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
7be74551-3580-4403-883d-9dd98490685b	07:58:16	17:31:41	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a3253815-caf3-4ac4-9a51-8fa3dfb6ec1d	07:50:35	17:33:45	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
42a96f96-6bc4-4070-98b3-4e7c3d0c6b87	07:58:07	17:39:05	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2a4e8aa9-8547-47cc-a498-96c8d14cb2b6	07:49:28	17:46:09	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a7cd80e5-0278-4874-a308-ee6ecebbf814	07:46:58	17:37:52	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
4afcc6a6-5e27-4e23-a84a-ca90c8563972	07:50:59	17:30:26	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
05fcf807-3f98-4cc2-b9aa-70a1fb514885	07:53:23	17:37:24	SUFFICIENT	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e8ac6b42-34a2-44b0-8828-e595e0502f38	08:16:14	17:05:20	LATE_AND_EARLY	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
263c985c-cace-4697-8ee4-d456a4084166	08:31:45	17:40:50	LATE	2026-01-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
3ed11753-5852-4c51-b88a-f702dc0f70cb	07:45:18	17:45:44	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
7c41f88f-92a3-429f-8595-39879c29174c	07:57:45	17:45:28	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9c36ca27-f2aa-497b-8173-d074a0a172ee	07:59:05	17:30:16	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a9d6fdf5-5017-4291-a18d-f8ead808e441	07:47:35	17:49:33	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5a2b2743-c2f6-489a-9788-9aeec8c4adaf	07:57:18	17:37:19	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
6481ae97-3607-41a7-a7ef-5f830d09fbce	07:48:26	17:50:50	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
398a1e6f-80e4-4783-ab7c-da1b7e8b8c8d	07:46:07	17:45:38	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
fb7be462-b779-4cb0-9d40-52b277baf19f	07:55:32	17:48:15	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
2b130b04-edd5-436b-b69b-a6617db0bda4	07:49:27	17:30:39	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
7ae953c9-e3f2-4e15-af64-3efa6cd7be68	07:54:26	17:35:42	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d5e3fb4f-645c-4cac-979b-33ae5481df80	07:53:23	17:32:33	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b539eab7-3947-48e8-b649-31d2dfe090a8	07:57:32	17:47:01	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
131e1b04-5850-4fac-bde8-2de103843ffc	07:52:02	17:50:24	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
69a83eb3-1fba-4eda-9bc5-158f119b0b8f	07:52:47	17:00:22	EARLY	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d87ab9cf-9d99-4455-9788-6f1375b32663	07:50:15	17:50:06	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
59b8a69f-bcf6-46a6-aef5-ea26b38e53e1	07:56:48	17:40:08	SUFFICIENT	2026-01-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a6064fdb-d8c4-4696-b694-16e0714861b5	07:53:21	17:50:11	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
69018b0e-aecb-45de-b73d-d76b0b0378f2	07:55:29	17:45:40	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
6e629e71-77fe-4f37-8161-d11fa4d29b0c	07:47:04	17:44:02	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d4f34044-6431-4cea-8a97-2950434991b9	07:45:50	17:36:56	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
8ffd7411-1fd8-4f2e-832f-3e7ece393e80	07:59:19	17:46:25	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f3632f4d-38ff-4ad3-ad2d-2c08000842c7	07:56:30	17:08:02	EARLY	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
48325106-0257-4c0c-b196-163c879269c5	07:48:18	17:41:55	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
49333b11-5417-43dd-becb-8b96370bd6a8	07:58:41	17:40:17	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
da5429d7-e214-4aac-b1b7-3e16b09b9894	07:50:27	17:42:47	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
918fb7f0-94ab-4aef-9172-17ac314af147	07:51:21	17:35:31	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e313d525-3fe0-4218-994f-b1fd559d9fbf	07:50:59	17:46:17	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
7a7dde1d-96cd-414a-91bf-e77d082469d9	07:56:27	17:32:27	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
5f4309b6-9026-44b4-bebc-b326c62f3e6a	07:58:11	17:47:18	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
ff7703e0-a870-49cd-a808-1c13ebc6ff97	07:46:20	17:39:19	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
72f7979d-8245-4810-9bdb-d6c0dd713c83	07:56:27	17:35:44	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
85450743-cc1f-456e-8096-7670bd8851e6	07:52:02	17:41:39	SUFFICIENT	2026-01-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
cdb19aec-56a4-4e5e-a4ee-2acb2852f186	08:13:40	17:06:04	LATE_AND_EARLY	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c920199a-3818-4dcf-bb88-8fe5ade6d593	07:51:23	17:46:51	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
562dd768-929e-434b-86bb-a66bef8ae17a	07:47:01	17:34:54	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
354fdefc-7476-46ae-bc7c-9cb471c9b4c8	07:57:28	17:31:08	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
717c20c7-5248-45ad-97b7-e8d6b6a51526	07:57:41	17:41:23	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
19566573-a6de-4f88-bdb1-086612822491	07:54:02	17:49:09	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b4208d6e-b96a-4643-976e-edc2f40795c6	07:50:23	17:44:48	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f4c8d062-5159-438a-af17-ad02c2242e43	07:47:33	17:41:25	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
63de8960-a3b0-433a-9ba1-ef43cb093368	07:49:15	17:33:01	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
44f84a5b-c401-47ed-b7ec-e3ad78bab45e	07:52:33	17:42:58	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e563ffc0-0a85-426d-97da-e43915b3b85f	07:49:49	17:38:45	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
80cf07f8-2e0f-4d7b-a7f7-71e98ed284dc	07:54:18	17:45:12	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
524230c5-b1ce-4918-a228-d2770200c6cc	07:58:04	17:44:11	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
58116493-458e-41e8-b690-27c43247e27d	07:52:05	17:40:42	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
af48336b-c8e3-41fe-aa40-9be92b6cb4c4	07:46:35	17:47:18	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
b860bc0f-b7b4-4531-8575-7bdb670865fe	07:58:10	17:50:11	SUFFICIENT	2026-01-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
0172ccd3-2d26-48bd-96ca-24b766d219a4	07:53:14	17:33:12	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
dc188e6a-ed75-4e04-92b6-34afe33fed88	07:48:50	17:45:01	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
4271c5f4-b60d-4486-9851-31420e7498e0	07:54:23	17:44:51	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
369b1056-e8f9-4355-bb70-46a076947ecd	07:50:39	17:02:04	EARLY	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
af2323e8-8f95-4983-b877-d2c36c8a1c9f	07:56:46	17:45:33	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f268ccef-3be8-4ae6-9ed8-29dc1a84165d	07:51:52	17:48:04	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a2279e58-da62-467c-83ba-a8bec04cbf07	07:50:41	17:32:28	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
498542a4-8b9c-479f-8728-83191d301451	07:53:22	17:34:56	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
1463376d-1a0d-4e67-9709-ef2917cd1095	07:53:40	17:48:11	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
bb950abc-5d3e-4931-9461-cf3c68a69811	07:47:27	17:46:58	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
1b73a070-f178-4b9d-abde-41c924dc195c	07:58:07	17:46:09	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
8c973060-d4cf-4205-ba0d-3d8c0f06e171	07:47:20	17:37:22	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
805babdd-458e-49ea-b9c2-53e92499b16c	08:21:57	17:39:54	LATE	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
8125dfcf-2caa-42ab-9c51-fdce40650320	07:48:40	17:47:17	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
94df87a6-d204-40a5-a7af-2b92ade98a69	07:49:39	17:47:05	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
5aa7182f-b89c-43c6-873e-eabffc22a456	07:47:37	17:48:09	SUFFICIENT	2026-01-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
4d487112-e670-462d-be32-5321a71f8650	07:54:46	17:49:21	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
29844bac-3511-4762-b218-ee4b360ef38c	07:54:02	17:30:05	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
185c582d-dd8f-4a59-ab38-b3c31d7a7a24	07:55:49	17:48:16	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
fec4913a-c820-4632-a6bd-751ac616959b	07:57:36	17:43:39	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b19b0197-9048-4d26-b1e1-1ebe4b55476d	07:52:56	17:50:34	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e97b68e2-5b15-45d8-9fd5-0f836024ef69	07:49:30	17:37:51	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b430a3f9-1328-41e1-830f-0f0505c4150b	07:51:19	17:44:04	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
38590b1a-afd7-41e9-ac48-41c50923b02c	07:47:28	17:43:30	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
3e60e0c9-909d-429c-b65d-75ca62f69312	07:50:38	17:34:20	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2ba5baa6-88c5-4a34-8845-40213831e594	07:50:46	17:41:25	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
e647bf54-1bde-423c-9a3c-b66fd057fea7	07:50:32	17:47:06	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
93b77015-ba8d-43de-a75d-b84eb0717ea6	07:52:07	17:38:28	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
906e16a2-094d-4c01-807c-0b9c7e5876b5	07:46:03	17:39:24	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d6ae0754-afd2-4f1c-b338-f572ce7417e6	07:51:15	17:35:52	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
0fb4b3b0-69fa-4b41-82d4-6c6c42811bb2	07:54:46	17:40:12	SUFFICIENT	2026-01-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
763545ca-e0a3-4303-ac3d-42ea5c2b623f	07:52:32	17:44:31	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
13e0219d-0842-45fb-a094-c0363849335b	07:52:01	17:32:25	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
743d7a46-4501-447f-b0fe-4dbc135eec6d	07:48:13	17:48:22	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
cb17b060-57cb-4a6a-8134-e954b9190db5	07:49:31	17:49:56	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b836c19d-e681-417c-adfe-586f264d7f2f	07:55:30	17:39:34	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
77720668-50c8-443f-9bc6-292d806649fc	07:46:27	17:34:56	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ce6a9aff-681c-45ee-b79d-9ae7b1e48d6a	07:50:48	17:42:23	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f5804675-9ea1-418c-aa66-054d3bea68f1	07:45:36	17:47:12	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
602b48bd-59fc-43c5-9df3-09fda515922e	07:49:04	17:42:32	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
65da288d-a39a-43ca-b3ca-df77f312c6f1	07:53:17	17:49:43	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
18e0aa13-a61b-4429-9170-dc9551ef88a8	07:47:06	17:42:23	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
564b9216-3396-4e25-9aff-8ce7562e37a3	07:50:35	17:41:48	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
8856a7da-bd81-43cc-b877-dbb751179e21	07:54:32	17:42:32	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1543ea48-a696-4a01-aa9f-f87fce885f02	07:45:08	17:40:51	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a4846799-c287-4244-abe0-2d05eb18e0af	07:52:09	17:49:57	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
17eabc99-298d-4c9a-a95c-354514ca5b45	07:50:59	17:49:20	SUFFICIENT	2026-01-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
190c75d9-6d4e-4d72-acb7-3bbb8d3a7401	07:54:47	17:39:37	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
e9fc5f65-fcec-4cc8-b09e-cad9f77da7b9	07:58:32	17:47:31	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
37a92741-0e2c-462d-9ead-817a5e15dfff	07:49:30	17:30:23	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a1b7510c-496a-40b7-9df9-0d7269ece474	07:46:26	17:48:19	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
41611e27-269f-4325-b3bf-6f238e25086c	07:56:55	17:50:01	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2f29d246-434b-42d5-8003-c2a189cca96c	07:49:41	17:48:36	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a5ac3811-54aa-493e-9dff-747888071252	07:45:37	17:45:10	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
d6c9fdf8-a218-41e7-adf7-d3d4396ebf71	07:56:39	17:42:09	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
d9b830c4-903f-454c-84c7-4ef0fa8819d1	07:48:02	17:48:44	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
efa7de17-c310-45a3-94e9-334819389573	07:45:28	17:40:26	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
0bb95bcd-ba83-4955-bea5-8f3068c9c5c9	07:56:13	17:43:32	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
88d696e9-631e-4c32-9721-c808a409f326	07:59:30	17:31:45	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
0a3754ce-ea12-4e3b-843a-d91829db7b7e	07:48:35	17:40:42	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
9972e4d1-9ee3-4fea-8f34-0c9054d7b9be	07:51:20	17:35:29	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
fc84418a-73f5-4c15-a604-9e0cf9ec2149	08:15:34	17:41:43	LATE	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3b449b79-2672-41a6-a1d1-ec5654306bb2	07:56:43	17:50:51	SUFFICIENT	2026-01-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
e4042307-a026-4746-9940-59455985723d	07:54:30	17:36:15	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d5c50bdc-6e82-4080-bb54-5b4658e29827	07:49:14	17:39:49	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
63e9e00e-dec5-4768-a776-11f916d3b30f	07:48:44	17:45:20	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
00a7c846-66ca-492e-8236-8def24e98eeb	07:53:59	17:38:18	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
12248c04-f306-4f0a-a70b-3eb5afd8d813	07:55:34	17:42:57	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c134a2d1-3e93-4941-b9a1-71db53837453	07:53:49	17:04:18	EARLY	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f5f74723-d5ae-455a-b73c-c24a6f82d8ba	07:56:05	17:41:59	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
319ae107-28cc-4922-b4b3-c8bbb0e5104d	07:49:47	17:45:13	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
faac0c87-7630-4089-8803-d120021a99d5	07:53:17	17:47:44	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
07c395e8-ad40-46e4-8c47-08f17bb709d9	07:46:39	17:48:15	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
c9e2c29d-31eb-4678-8b4d-53a0a23c548c	07:55:57	17:46:14	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
6dad2780-b566-4727-a9a2-7def767469f3	07:45:06	17:43:21	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
ca32a3ac-1517-4261-a417-e97230a2d110	07:46:43	17:34:00	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
50ea82f5-530a-4559-850f-73e2618338ce	07:50:26	17:15:30	EARLY	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
7a7e6b34-eb2e-4a9a-b471-c9262cd13323	07:57:18	17:40:18	SUFFICIENT	2026-01-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
dec996bf-09f1-4fed-9edb-dd356d5cd70d	07:59:49	17:32:41	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
32802b88-45ff-4f04-b4da-4126ccad84d0	07:53:47	17:31:58	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
98414b97-93aa-453b-b944-dead10efee5b	08:18:56	17:35:59	LATE	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
e2435a99-d778-4e38-960e-98f14f7706c9	08:31:25	17:45:11	LATE	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
03984430-177e-4cba-8beb-152c3195d55a	08:35:55	17:39:56	LATE	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2f86ea37-4565-4777-8614-21ca4d1b6972	07:49:36	17:49:06	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
e73c8713-9df6-4dca-abf0-7c4fb18ab565	08:15:18	17:44:41	LATE	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
2ff8afd0-cdac-47a1-812e-a3e8e0ed0be2	07:52:56	17:34:54	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
30126039-f821-4f4f-8309-5841bad4d193	07:49:12	17:33:21	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6d33816f-1b54-4eb7-b6e6-f7ff75c2ba18	07:52:41	17:38:45	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
9f1eeb2d-bb1a-4b68-bc6b-898e0606604b	07:56:21	17:39:36	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
140fcbdf-efd9-4062-a76c-f57291618fa3	07:48:11	17:49:54	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b2d1c045-b379-4b0c-bc63-19e4a0beeede	07:51:52	17:43:32	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
7661694b-6c26-4275-9941-139cff092659	07:51:42	17:33:11	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b876db13-ed86-4c49-884e-9d39cbd447da	07:55:20	17:07:00	EARLY	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f16f7ad0-d18d-4da7-85a3-d48b81d435f8	07:48:28	17:38:21	SUFFICIENT	2026-02-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c5fcdd7f-dcf5-43e4-8771-34902ae26496	07:56:36	17:30:16	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
0714d58d-cead-4439-9d41-effdd2de3673	07:56:15	17:31:42	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
45f73dae-bb92-48f7-a180-ab2e872afc42	07:49:10	17:42:43	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
338e87c1-69b1-402a-825f-b1b54fd3c8b1	07:59:56	17:39:44	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
7c818edd-dde4-4e9c-bf19-420cae044d05	07:59:18	17:41:39	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
80c70f9b-b585-49bf-86bf-95e96ab17cf2	07:47:30	17:34:29	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
3259e57d-66ad-4a75-a9fd-bb4ce1f5ebe3	07:54:23	17:43:44	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
14ae217a-c4aa-4eed-af74-6defebbed21e	07:52:48	17:47:51	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
68b6d715-7533-45fa-aeba-fc6a367220da	07:48:48	17:37:43	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
5464d48f-d830-4659-adef-227cf69bb18a	07:58:50	17:32:33	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c4ed73a8-8457-4469-9af3-1f19bea642ab	07:56:23	17:32:58	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
66f007bb-3de3-45ea-a1ca-1ad99d198cb0	07:45:53	17:47:57	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
f7042973-104a-47ca-b2ae-955ac9a424ff	07:54:34	17:34:10	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e80915d8-39d8-4ddd-867a-5d45a74c5ff6	07:53:28	17:33:43	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
c043c6e4-fc23-4016-81fc-071e19f1bc8f	07:54:31	17:32:57	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
cc81ff9a-1e44-44f9-b505-9deb72e13cf0	07:57:03	17:44:08	SUFFICIENT	2026-02-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
51f9741a-c95b-44b3-8c2d-8c179a78f1fc	07:52:36	17:31:35	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a18c09b4-03e5-4894-85b6-13591494f6f9	07:57:19	17:30:25	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
10805a8a-58f3-48b1-9281-775f5510ed14	07:45:47	17:36:37	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
85261701-05a0-4c2f-8d2d-f2ba2a7ada31	07:51:22	17:32:34	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e7aff01f-9168-4641-8992-ddcdf673f276	08:07:59	17:20:02	LATE_AND_EARLY	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
decf18de-0639-4de4-8527-f247097682af	07:47:49	17:34:49	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
c93c8ff3-48b5-4c3a-87a7-5e65e4f4b4c7	07:56:41	17:43:23	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
0044e41d-a02b-440c-a131-9f38daf2bbea	08:17:28	17:17:24	LATE_AND_EARLY	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
04c084fc-486c-4a31-9ef2-e67cf2d3960b	07:55:55	17:47:08	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a03a4bcb-9cd1-4494-b9c5-f428b8b1b9b4	07:50:07	17:35:34	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
0ec09474-1571-418e-9d6b-74aa1f26df84	07:47:46	17:37:53	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d97313b0-6860-4fbc-8253-ed95fb9c1ceb	07:45:19	17:44:43	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
57e9dab9-7c3d-44ae-96c8-278231b6f929	07:51:34	17:42:52	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
2866476a-d63b-4032-b7ab-f98c66f85733	07:52:22	17:34:17	SUFFICIENT	2026-02-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
411eedc3-d6a1-409f-965d-5960c795b29c	07:59:46	17:33:02	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
eca23dab-f3eb-406d-a8f3-a05a67bc0432	07:51:39	17:30:15	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b15f1a11-5bb1-4615-ae75-06b3f78127dd	07:46:38	17:31:28	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
f23eff71-5879-49ab-8e67-54930ae46a2f	07:56:55	17:31:15	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
0ab4b74a-7b66-4aeb-b32e-70c34390d070	07:51:28	17:37:34	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2654b5dc-7420-4a61-8c13-611cb2f07774	07:58:49	17:31:08	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
efe8e14a-330a-4626-98a0-0fe563828ad3	07:49:14	17:48:20	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
128f3eee-33cc-4a4c-abc3-d46b7c90c9df	07:57:43	17:40:15	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
c1880042-9149-4221-ba17-c22cc3cfe202	07:47:42	17:46:14	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
54d54cec-7a6f-42aa-afef-de777a680166	07:49:03	17:47:37	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e3e2c92b-c7b4-40f3-b698-a05ebfd00966	07:59:11	17:50:43	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2fda40cc-4b25-49f6-bb2f-f78be79e86d7	07:52:03	17:41:41	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b574a962-7f67-4a1f-8a9b-6946a1e7dddb	07:57:33	17:40:44	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
94a87ce4-f5d0-49a1-b4cf-943d451b55e0	07:47:19	17:42:11	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
75a11217-350c-49cb-91f4-dabf153679f0	07:52:15	17:37:19	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
2833960b-9699-4b94-87ce-1d9dbfc1f2a9	07:47:51	17:44:58	SUFFICIENT	2026-02-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
8a0f1f75-4886-46ef-8730-90fddefc97a8	07:51:26	17:47:33	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
f0e19044-140f-465d-85a8-e91001020421	07:48:16	17:36:21	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
2c491d1a-bd81-45d8-80d8-0877c1937bf9	07:59:28	17:41:05	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
e9525d17-3683-4be4-af10-7e3ae3ad4793	07:58:12	17:31:17	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
bd2c9a46-8bb4-4922-8036-8379d5fe7680	07:54:38	17:31:55	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
cac38ffd-4bfa-4a65-9f15-e254b90f7228	07:57:48	17:48:46	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
cb15da3a-6475-4b15-8709-951c0303db8b	07:48:30	17:36:55	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
37da717d-37bc-4483-bdce-a8953422c33b	08:14:58	17:30:13	LATE	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
d9d7625e-8319-466b-8133-bb12511c3acf	08:35:47	17:33:47	LATE	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
f3acf62e-1081-46cc-bab2-62f5c21bf1a4	08:20:58	17:12:44	LATE_AND_EARLY	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
252492e5-e54a-4b82-b736-a1e57dd9f58a	07:48:25	17:37:35	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
af908487-75dd-4f0c-94ec-15185216e1c7	07:49:24	17:44:34	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
024f9b18-b93e-441f-a84c-eb6c2a7d8103	07:49:16	17:41:32	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
bb44fd5f-0128-4d4d-aff9-3e18113dde20	07:52:06	17:45:48	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
04dba4c2-c4a0-4e50-ad92-ca0585356c15	07:59:13	17:41:20	SUFFICIENT	2026-02-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
5a43f50b-c19e-4c6c-94b6-1c6d1f0206dd	07:54:55	17:37:47	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
e793e47e-ab77-4804-ba6b-1219f3fddcd6	07:49:35	17:48:37	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
fc1fd121-d123-41ac-b059-e0c3b1d41563	07:49:09	17:36:21	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4d26f109-8c88-4a64-b368-cc801345e8ad	07:54:53	17:37:31	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ff8b9962-ac8e-4b7e-9dfd-783f5685493a	07:55:21	17:38:48	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a1fca52a-e81b-47c5-8e4b-0ae517eb06c7	07:56:41	17:45:29	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
2f4b2b86-153c-45e1-a4c7-dfdf476d727a	07:57:22	17:35:08	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a4b91363-693b-457a-a5b7-26e3faafdc4d	07:52:11	17:47:41	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c02f7e73-a0aa-4bf3-b271-6078a94fdf91	08:21:02	17:32:52	LATE	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
22b2e7ef-e235-411b-980b-e2c95729dba5	07:57:00	17:43:08	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
bff9d0ae-6771-4d30-8370-7989627c29b8	07:48:04	17:34:00	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
48ec1371-4f7a-4d27-87bb-21e14f417479	07:52:23	17:31:39	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
bd518421-3b30-43f8-b992-252f70f8b729	07:59:39	17:45:42	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a4b04ffa-afa5-4fa9-b7b3-0063bc336a0d	07:45:34	17:47:26	SUFFICIENT	2026-02-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f33d813a-085f-48c9-93e4-31d757eb54f0	07:53:46	17:38:34	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
bd4ff66e-4018-4b82-94c4-cf96595f36bc	07:48:32	17:13:51	EARLY	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
6117de3d-869f-46b6-9707-117d08f22fa1	08:10:06	17:33:33	LATE	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
06850810-0ea3-4f8c-870a-0c341284e143	07:48:39	17:46:16	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
846bf478-da47-4eb8-b336-44b6cdcbd39a	07:49:50	17:42:05	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
aace4d05-42f2-4b36-a916-e2df3da6cd4e	07:51:29	17:48:15	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
1153c212-db20-4dca-8121-00f945f8544b	08:12:19	17:07:41	LATE_AND_EARLY	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
cb831aaa-7c6e-448b-9be7-a1fb4c1659e8	08:06:05	17:17:24	LATE_AND_EARLY	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f45f2477-dfee-4b46-8cdf-8bb6a494436a	07:52:03	17:50:00	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
71e6d7a4-7f67-4507-bd5d-42b4cff8ca5b	07:46:31	17:43:41	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
5072b8cf-e663-45c4-af7b-618d8152058b	07:54:54	17:33:57	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
fece670d-78ae-4473-9b51-2a24b9113f3c	07:45:14	17:36:57	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
7573cee0-e92d-4854-8fb7-9ff57af1e802	07:59:36	17:45:17	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
05bdb0b1-d52c-4d91-a861-b2e5441a6890	07:46:43	17:38:57	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
6317006d-ecb4-4fd7-a05a-007b0f99ac61	07:55:02	17:35:59	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
4a726efb-3f0b-4e93-8daa-9449b90cb421	07:45:13	17:48:09	SUFFICIENT	2026-02-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
7ade949c-6a4c-4cf5-a254-6f86b6f71cba	07:56:52	17:42:59	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
ceb77a2e-8c83-4159-addb-79c43ed2de6e	07:47:36	17:37:36	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
8fbbec6d-08bf-4fe1-8abe-a3e2e5e71c0a	07:51:43	17:47:21	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5f54f5e4-c43a-44e8-828d-dc08b6b4a72a	07:56:08	17:32:32	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
4872fbb0-6cd5-4a50-9482-c3fe32952820	07:50:03	17:33:27	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
d1dbb2c4-9c2e-40ca-8b19-755e16e5db70	07:46:21	17:49:49	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
84159cd7-d208-437d-bf7a-b2a53872ee36	07:54:25	17:40:01	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
56ac26af-2402-4efb-a0a3-438bb1ce8700	07:57:28	17:45:14	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b6ffb414-dd1e-492a-82b0-116ee53b2b60	07:51:27	17:35:43	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
4675e55b-3436-4ee1-a4d1-db6e5c4ea483	07:51:05	17:49:18	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2b7adc11-cffb-4853-9c53-6d0022fca5a4	07:56:04	17:32:17	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
dbfd1e6a-c665-4887-95f5-20ad02c27455	07:56:50	17:50:09	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e71c586d-c102-4525-875c-7567bf6558ff	07:50:23	17:33:05	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b4e40b14-b64a-484a-8d1b-62b47ac5ab48	07:49:28	17:41:48	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
fed9448b-e44f-4341-a4e6-7cf35a7c4e4d	07:47:05	17:35:27	SUFFICIENT	2026-02-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
81da611f-e296-4840-b808-5bc140ef96c8	07:53:32	17:43:06	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
6f7e4c62-fd96-457b-a683-1d01e400cfbd	07:50:35	17:32:38	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
be940c6b-10da-4603-a6b4-e36c9acee174	07:50:55	17:42:00	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
31215473-d736-44fe-9d94-b682a4145311	07:51:49	17:32:46	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
60d5c575-6bd9-4768-a6ec-547970da1a79	08:33:15	17:35:43	LATE	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
017bfce4-ce4b-42fd-a3d5-d4aaca25a5e6	07:47:17	17:39:17	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ba86d28c-ce16-47dc-aedc-e766e1773c18	07:46:10	17:43:17	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
be06d555-054b-4c7b-bf74-dcf384fd84e9	07:52:50	17:32:23	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
8c8ec879-17cb-48be-b5be-7a751191387a	07:48:46	17:50:31	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
88d19ac7-2dd9-4e63-9f10-b8802455168c	07:48:29	17:33:08	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c1fcb4f5-1180-4deb-9ec2-b02edac92d88	07:51:21	17:49:24	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
47ce1494-7c6e-479b-a0f8-b15ea3450abc	07:50:28	17:40:27	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
f7e78f3b-787a-4926-9681-677081b1151d	07:58:41	17:49:08	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
7155b6e6-ab5a-40a1-9abd-8b940ab81035	07:54:44	17:36:30	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
be164225-595d-4156-9375-5cce30ee0145	07:51:20	17:39:47	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
860ae844-9035-4cec-8ab6-3cf62147e9d3	07:52:36	17:37:20	SUFFICIENT	2026-02-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
0fd438f9-6cf1-449d-bf73-976f37a18766	07:58:50	17:42:23	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
11987c6d-f511-4877-8b4f-fd38bb6342f2	07:54:12	17:48:34	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
8dbe146b-574c-459b-a3b4-e3801495e401	07:57:35	17:30:46	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
b2d8c316-0038-43a3-b0e1-598efa19cfba	07:56:13	17:44:51	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
93b65738-c561-4970-b399-acbe6d5477ab	07:56:04	17:43:43	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
52241c58-f805-43ef-90e8-b7dfb3adb21c	07:55:19	17:37:16	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
318248c6-12cd-4479-bb91-bfc6ab301e1f	07:56:27	17:42:04	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
7cba9b28-c84b-4999-a21b-b0088c6c7b1b	07:54:30	17:48:25	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
7571c6ab-086b-4210-a1b5-0d61eb9595c9	07:59:58	17:43:34	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
990256d4-c6a1-460a-8982-e462c6f42606	07:50:44	17:47:38	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
4cfa5d95-517e-4f35-8f2c-e30ff4628f41	07:46:06	17:37:42	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
58d8943c-8b88-48e0-b725-57cd24b57699	07:47:41	17:49:02	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
93adc7be-f6a1-42d0-aaa3-095406b39856	07:55:43	17:50:25	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d5eaf13c-3e3b-4c67-a91c-9887b49b2e49	07:53:50	17:13:06	EARLY	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
302656f6-de94-4798-a196-6d184926a65a	07:49:14	17:46:47	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
29b65f2d-a753-4415-83d7-743465b6d35e	07:54:44	17:48:14	SUFFICIENT	2026-02-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
25ee3ae6-71b6-4ce6-b138-71798d727d7e	07:51:29	17:48:44	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
761ac569-80df-4f5c-a7c2-531b1a98c423	07:50:01	17:45:06	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
de42c87c-a7dc-4b78-af7f-eeea1469d05f	07:59:05	17:33:53	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
3147d9ee-ea44-4f01-a117-d3091a3b556c	08:09:22	17:39:21	LATE	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
c738c2e9-2773-4279-b50c-bd5ad4d5ea70	07:48:33	17:45:22	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7f5c4203-f353-45ac-a218-0f2e510a2f1a	07:52:46	17:44:20	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
5b56c442-878f-4df4-917d-96ea35db10dc	07:45:51	17:33:01	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ba66c4dd-8691-4c12-ba01-46cda39957cd	07:55:06	17:35:59	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a0d8f9c8-2e85-4e28-9662-6a79ed8cf125	07:51:33	17:05:35	EARLY	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
790a2a68-9e44-4629-8cc4-9ccae6e34345	07:53:27	17:44:14	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a7010a35-a996-48d9-9d2d-f32a12faf7a7	07:55:11	17:35:40	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
07c883a5-7222-40c9-aa73-1bfa29b85c23	07:51:01	17:49:56	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
01b020be-bc29-4735-8c59-caad1b3c99d0	07:54:27	17:42:00	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
8251e238-d0cb-4ebb-9bbc-3e944b6f567d	07:48:17	17:32:36	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
3606a8ac-e3c5-42dd-8a4e-a7365352f5e1	07:58:34	17:35:23	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
2a7f07b7-5d6a-4814-8aff-2a4b2354b2ee	07:52:07	17:38:42	SUFFICIENT	2026-02-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
af581d0a-a8b1-466c-845b-2d745fe44374	07:53:40	17:40:38	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
9fb19395-aec9-48c6-869a-313d7084377b	07:51:37	17:33:22	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
0741a8d8-ef2a-4d1b-85a3-c93737ddac4c	07:52:39	17:35:52	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
e7707a91-d84d-466c-9b55-2b79706e947e	07:57:19	17:49:37	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
029a8cf9-dce6-4ae5-8e5c-94d11b1802e0	07:47:20	17:33:15	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
49929d60-7987-4545-9855-2a54d5aaf57a	07:47:23	17:34:32	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
404e8168-15cf-4577-b8a6-0f5c419eca37	07:54:08	17:48:24	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
3c12ea00-e858-4b16-af57-830f5cf9c7fd	07:52:40	17:47:44	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
63062b0b-c5f4-4d2e-b81e-b6ebe155317a	08:34:11	17:35:31	LATE	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
78c19ffc-df50-4b72-b3b5-0bdf630f682b	07:47:20	17:44:39	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
eb655d99-6419-4fb1-9aa6-ecdfd763ce4b	07:50:00	17:45:08	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
e90b1de6-2b25-4ae1-8325-808278db47e6	07:51:35	17:46:41	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
05b22557-1dc4-4252-9082-c515524e9de5	07:55:31	17:43:45	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
dc108363-a6cd-498a-b8fd-cbd60c979ac5	07:52:10	17:32:36	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
2b719690-3528-49ee-9a8e-bb514ea75b49	07:57:14	17:39:02	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
6943146d-de78-43c7-8884-a844569fb865	07:53:18	17:35:49	SUFFICIENT	2026-02-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c9d05446-788d-4464-be9e-3c9e761fb201	07:56:49	17:45:35	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a83a9f6d-c533-47da-8eb0-4ebef1e05362	07:54:07	17:38:49	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
c51b7bdf-016d-4b8b-aea4-61af9fa199a7	07:50:34	17:31:48	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
8fe82828-c058-4f17-a950-d57fe80b8335	07:53:13	17:43:06	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e73f732a-813a-4650-9816-1510ccb3ccc9	07:55:48	17:37:19	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
627352d5-9db8-4002-8574-70ec73f73506	07:45:28	17:38:22	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
249ef671-8c93-4641-84eb-113fa69326bc	07:46:28	17:33:49	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
3d329776-5d0b-4fc3-acb5-b21f419ffa03	07:48:51	17:48:44	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
8f2f213a-496d-4314-9b8d-f343ab594b44	07:56:39	17:50:27	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
077c2844-ec24-44f8-9bdb-eb1c4ccf7c03	07:47:50	17:36:52	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
f364c7d2-507d-49fd-a1c2-817d55134127	07:45:36	17:41:34	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
30e2b8fe-8127-4b0b-985d-d08adeba470c	07:53:10	17:40:45	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
532ccaa8-0aa9-48ac-8912-235520976d31	07:54:17	17:46:57	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
5936c5d7-e30d-4d92-a98e-131f63436d69	07:46:08	17:43:58	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
7db9e89f-88c3-45fd-a014-8b870137b290	07:49:55	17:50:08	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f4732c57-ab38-47c8-9028-7cbe730bf7b5	07:47:15	17:34:45	SUFFICIENT	2026-02-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
ea74691a-0321-493d-8c9b-c16af7ccdfeb	07:48:48	17:42:31	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d429476a-ed91-423a-a5c9-efcac55005ac	07:55:17	17:50:26	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
07e4b8c9-2524-4217-ad50-cb18c49b14ee	07:46:40	17:32:25	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
88f798d0-0396-47f7-9b76-1c59f0941674	07:49:44	17:41:29	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b366a65f-d3f0-4e7f-b70e-814b9502bc3b	08:15:37	17:30:55	LATE	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
35686941-e0f2-42c5-91c2-75ed034240c4	07:56:05	17:44:40	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
da466735-d69e-42aa-92a8-2a0e7cf3326d	07:50:54	17:32:50	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
57cc9959-252c-4a13-8a88-8680667e6b8a	07:48:27	17:36:31	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
7f1ff539-0c4b-43e1-8647-ffcf3b4e558d	07:58:18	17:40:35	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6ea4b645-d605-463f-993f-a2ae680bac81	07:54:54	17:45:50	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
0df58d70-a896-4801-940a-adcf2c17443f	07:55:48	17:31:02	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
00ba2b30-59ea-4080-87df-01f0714f3381	07:57:53	17:44:01	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b83ba6d6-f10c-4615-85b5-20cb53db5f40	07:58:10	17:44:29	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
8ef89acd-9574-4d66-b17f-47fc83cc52d6	07:51:12	17:34:56	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
ac946b86-f8d8-47c3-be4c-10decb7faf5f	07:47:55	17:38:05	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
59b9892f-90aa-40da-b56b-d8fd54d17632	07:49:05	17:41:42	SUFFICIENT	2026-02-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
9718ef28-d59a-4e06-8054-8a5da32ea19d	08:10:03	17:42:40	LATE	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
594a6340-1ea1-4cf3-a8e8-f35ab00d78f5	07:56:48	17:37:27	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
69b71ad8-7352-441f-8bd6-167d50aea794	07:56:06	17:30:13	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
f7ecd498-75e8-41f0-aedc-0807fc40ed61	07:47:37	17:37:33	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
65dd9474-1b1b-4c35-aa0e-2a16f0b65f34	07:45:00	17:40:52	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b4744417-63b6-4745-a06c-de2013cefb67	07:58:27	17:34:30	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
d675f8e7-60ac-48ec-90c8-7d83422cc6a5	07:51:05	17:33:06	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
e9a871c5-de9e-4e4b-a903-5809251c9845	07:59:19	17:34:24	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9b86e45a-a5a8-43c6-94b5-1e2f3ee88556	07:57:55	17:34:41	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
5c21fd71-f46b-40cc-99c5-4f847ca12fec	08:09:04	17:05:39	LATE_AND_EARLY	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
bf9cf07f-6e41-4dbe-a167-edea40959939	07:52:22	17:36:40	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d69b51e8-001d-4d5e-8463-c55e16468ab3	07:59:26	17:49:43	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
fd40c9ff-7835-4400-9d97-34a1d12b032f	07:48:05	17:33:08	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
43073012-0bb4-4310-9f58-ed4d9e75092a	07:54:46	17:42:22	SUFFICIENT	2026-02-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
9016eb4e-472a-423a-bb8b-2cc5032c5bec	07:53:50	17:04:15	EARLY	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ae7a7bab-ace6-4adc-93c2-a7c5ccb3e495	07:46:15	17:47:38	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
5948a760-5248-4c02-bfd8-0c4c5ce22111	07:54:18	17:30:54	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a69a8d78-e2ec-4dc2-927c-9a7752bf73c1	07:59:19	17:36:33	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
3ae986fc-07f9-4efe-8ae1-bb09d4f4d3fb	07:48:47	17:42:18	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
58a07946-c7a8-459a-9f5f-803bd9705c4b	07:57:57	17:37:31	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
96adef69-0c31-46e4-911e-2b8b843d3354	07:48:31	17:50:38	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
264cafba-a83b-4552-af1f-0280efac3a2e	07:59:00	17:41:59	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
3bb963f8-0813-46b9-a114-feb689499126	07:51:55	17:48:26	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
7a47b4fe-fcd3-45af-b68e-60fcc11af59e	07:55:11	17:45:49	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
0f2f00e2-7e2b-41cd-9c74-fd6759a884fd	07:54:04	17:30:16	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
16a80685-3aad-44f5-bbd0-b4e248f240de	07:59:03	17:42:32	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
30fbfda5-7881-4b7c-ab67-06e3b0a5297f	07:56:32	17:43:27	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
c2f9af36-c0e9-4688-9117-61601ed66d23	07:46:40	17:47:34	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
7201bcfc-5897-4222-ba2a-752e88f7c685	07:49:05	17:39:05	SUFFICIENT	2026-03-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
63c6ffeb-0f81-4fd5-bdf9-bb6f9550e5bb	07:48:51	17:34:34	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b6e45f29-1a8e-49c6-b461-29a20d3bbfa1	07:54:40	17:50:43	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
0f62e641-b327-4022-8e62-462981828433	07:49:44	17:43:46	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
22d9e16f-3e97-425c-8937-0940711fe62a	08:12:03	17:37:05	LATE	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
6c9c582f-d298-43d9-8a67-b9a98cfb19aa	08:08:29	17:31:19	LATE	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
3f72eeb0-c08b-4cf5-8371-edbf819859bf	07:55:47	17:35:07	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
952a254a-a907-4c8b-8084-0441630b6722	07:47:44	17:30:10	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
c2b79a3c-1028-4f48-b473-e667aabce8bc	07:50:33	17:46:50	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
5200429d-035e-4219-b3f2-b2ff3bbc3c15	07:49:10	17:41:08	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b921d584-d85e-4ab1-b4cb-6f0bc56bebcf	07:58:17	17:33:49	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a8e59a8f-ec38-4256-a2b3-5663c98cacb5	07:50:51	17:43:17	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
081f86e3-d51e-4724-bac5-5d1765156259	07:49:45	17:48:40	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
916f1d81-7425-4c98-88b2-b0d8e78dc8c6	07:52:32	17:41:03	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
8924e6cb-c828-44a5-baa2-949ae50dee8a	07:54:10	17:41:10	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
1606ef8c-616c-4c71-a0ac-196db79cae17	07:46:57	17:48:43	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
01af7ee5-ca08-4a83-b2f1-0578b81bd1cf	07:48:47	17:46:00	SUFFICIENT	2026-03-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
14ba5bc3-2020-4f71-86b2-3fa52b095550	07:58:00	17:37:02	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
5182ce09-3a58-4b63-b5f4-80042d835370	07:51:58	17:34:11	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
338c4b49-3dc6-4478-9975-e4e33f07a7dd	08:32:02	17:43:14	LATE	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d0a0aa23-bd11-4984-a535-5b745bef7433	07:51:58	17:40:17	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4e03922e-b524-4d77-8773-62d7279d6ed1	07:54:23	17:33:32	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
68fa8f21-89af-400c-8eb1-8b3448e025ce	07:45:11	17:37:51	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a9aa9f3d-0af8-4922-8b4d-7eeadb302a8f	07:45:25	17:32:56	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
3513756b-d572-4054-94ee-24e72979c2d1	07:49:49	17:39:20	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
d29bbd44-8ecf-456e-b68b-48ad39544adc	07:52:00	17:41:12	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
e11bf31a-ef0b-47b2-ae32-5dddd43287df	07:57:19	17:49:15	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d06976dd-dbd0-4392-afd7-67bad347b412	07:54:31	17:36:46	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
0bf40f50-021b-40d1-9b07-70661f0e1579	08:29:50	17:37:09	LATE	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
57b2489c-7a81-4f96-abc3-02331c29bb84	07:51:01	17:37:34	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
c06a662d-4444-483b-a0d7-a87b56b6e50e	07:58:44	17:30:21	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
c8c09366-9a51-4f04-a471-998bae75e007	07:55:24	17:39:06	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
93c46eb3-65ac-41ad-abf8-b444445a3302	07:48:26	17:45:03	SUFFICIENT	2026-03-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a8392d7a-260a-41fb-9667-f2dfcea536bf	07:50:45	17:08:05	EARLY	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
6b0d26c5-5891-4db4-87af-28954a4b9e6f	07:48:57	17:46:26	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a6199ad3-d8b1-4f4d-b1a0-ae28af49c271	07:50:29	17:32:37	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
90b5e78a-7808-4be7-862e-ba6320b311a7	07:47:40	17:42:04	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
dac113b4-36dd-47eb-9561-51178c1727dc	07:45:27	17:34:15	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
35f5d7c7-e10c-41be-bbe2-6c07558d62f5	07:58:20	17:42:44	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f604513f-ad0f-49ba-aed7-98740f39c12e	07:50:20	17:44:17	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
d176c876-aee6-4c53-b59f-def8fbe045cc	07:48:08	17:48:06	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
2d9247ed-039e-4aa9-a25f-dabd2d1a1b5d	07:47:28	17:44:20	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
d836e46c-39da-44db-9bf3-c31ad95a7f50	07:53:22	17:36:28	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
39c48dbd-318e-4f37-842f-3a7ae45ed1f4	07:49:54	17:33:05	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
0d040311-c991-40cc-9cf2-bc4e8ec1ff41	07:55:19	17:49:02	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
ff8d44cf-a99d-4f31-8e5b-9e64b357bf97	07:58:20	17:34:05	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
920a1ad3-108b-424b-ae74-1e772cd487a5	07:50:25	17:46:03	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
9204c1fd-2f84-4303-94da-bb8b3892bc98	07:49:52	17:35:01	SUFFICIENT	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
5064038d-f004-4df1-a252-be37f876eb7f	08:32:28	17:37:06	LATE	2026-03-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
db5a2c86-9cd0-4eda-9032-9a6da71a9809	07:57:50	17:34:07	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
db047fc8-02a0-4b3d-b422-e27c779fcc74	07:58:49	17:37:08	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b833f08f-3835-4c7e-9caa-8c90b5ad33cb	07:51:23	17:50:41	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
66481c03-72ba-4812-8f13-157f2d50dcf7	07:54:16	17:32:01	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4827067a-ce96-4442-a30f-de8a23826566	08:11:57	17:19:51	LATE_AND_EARLY	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
bd668416-07ba-489a-85b4-7cade6f5d733	07:59:54	17:40:07	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
9a303ce7-d09a-4811-8c32-99fbe1e5e8d8	07:52:03	17:35:59	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
5d9f6a9c-6cdd-4620-88c1-795105a28b35	07:58:46	17:42:31	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
38e1670a-e6eb-4a5f-b681-75e33507856e	07:55:27	17:35:22	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d81b1c59-3310-46b2-94c5-d2334eedeac9	07:47:17	17:38:28	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a0e9bdb5-6801-4c1a-ba89-628c5cf25501	07:45:39	17:49:39	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
2f3d9ccd-238a-4daf-af4d-1d3a9ebbf5ce	07:49:31	17:43:56	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
2ecbf695-8df7-417b-9e13-54330e196421	07:45:05	17:38:24	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
3c05e5d1-ca9a-40af-83fb-0668d6c0865e	07:48:41	17:46:15	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f7df3c79-a22a-440f-b9a3-8bd16f702b8f	07:57:34	17:30:24	SUFFICIENT	2026-03-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
8fd3ec2e-76b6-4647-967d-ee37bb44852b	07:50:30	17:47:50	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
eeb40146-a465-45e8-9986-1c579d1844c8	07:59:36	17:46:20	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
dd629b48-d133-49ae-9fbd-f2eaa62d6962	07:47:01	17:40:38	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
42ae788a-57a6-4517-9759-0de92c243bd8	07:59:51	17:38:03	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
d9683214-f138-4220-946a-a03622220880	07:52:33	17:41:49	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
447901fa-3cf1-4a21-8b1f-e533d7d68931	07:48:10	17:33:15	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
4cb12e23-d218-4e0d-afa0-f1517b18bcec	07:49:34	17:31:48	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
b41a3d4d-6767-4d87-a3e1-427ea8aa78cb	08:12:36	17:17:22	LATE_AND_EARLY	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
63f9627c-09ff-4fea-a0c8-2c55bf78460b	08:32:11	17:35:15	LATE	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
5b57c4e9-b65d-4d67-bea2-8354802ab671	07:57:47	17:41:58	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
38c43760-cc96-403a-a994-8f735916ad55	07:56:44	17:41:36	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
ab4e9a2b-a4fc-4958-b17b-c30cfbaee8fa	07:54:12	17:45:34	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
637389d8-255a-4b42-bb81-107ed725d675	07:52:02	17:32:03	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
77c4e049-fcc9-4f42-9318-f14fe2add0e7	07:48:01	17:46:30	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
5e1f3043-09dd-4f7b-ae00-9ab459ecd755	07:59:39	17:36:51	SUFFICIENT	2026-03-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
d2378f2b-2343-4bcf-89bf-5d65e86aeb8b	07:56:11	17:40:03	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
5d86870a-8d45-48db-9d07-640e34b4a322	07:54:45	17:34:49	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
ba93a3c4-1ce5-45f2-a365-9a31304d2aa5	07:53:55	17:41:04	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
66bb5a76-7c39-4b53-9756-cfc954f54d5a	07:55:25	17:48:06	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
694a0874-91f2-47e4-83ea-8ad340a93988	07:50:08	17:35:46	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
acaede0f-3f32-4884-80ae-5a6e7cbc24cc	08:30:40	17:45:41	LATE	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
d8f16826-21a3-4a6b-80f8-2b0189deb259	07:56:35	17:49:50	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
5b9a2fa9-ecf6-4ad3-9782-678946feea7c	07:55:37	17:35:24	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
cbde7fdf-46fc-47af-9a34-e8959ababc6c	07:56:18	17:34:11	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
01eb627b-895d-42b8-bfd4-b4f86b7b1da3	07:56:36	17:42:54	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
7f6f59ff-aaea-4d4a-a8b5-d722714eac88	08:06:11	17:15:58	LATE_AND_EARLY	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
574fd170-bbfa-4fef-b1fa-2d148c415048	07:54:14	17:50:36	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
325910db-86b7-4485-a2c1-eaeb2541ca9f	07:52:09	17:40:47	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
03317a1c-410b-435d-afb2-7ffcc451549f	07:50:20	17:35:40	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
5d1719bb-9b71-4e54-a5d5-5dc1b33b04e9	07:46:52	17:50:46	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3e2ac1c4-11ab-4c69-b1c6-f712929fc6f9	07:52:00	17:38:13	SUFFICIENT	2026-03-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
5f94b646-603f-4331-a81c-a7ca0c089439	07:46:22	17:38:50	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
e0be8f4f-9bff-40f3-9259-9b0e16e279f3	07:45:03	17:42:28	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
75e2eaad-b623-43ff-bc43-d541f9171792	07:47:56	17:43:31	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
fa032eab-53a4-40a8-9bc3-a773617b6db6	07:50:34	17:42:06	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
18c02d39-4db2-4c55-89e6-f62e3a56f29c	07:57:55	17:48:41	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c5b4ec7a-4541-4230-a790-06d0dba979b6	07:48:10	17:44:04	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
fc515b85-9866-48cd-82a5-a9cc1e86100b	07:45:18	17:30:20	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
3392e3de-39be-4d49-aacf-88b5fd1e9fcc	07:46:04	17:40:10	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
fa4b485b-a15a-4cc4-950e-147e6feb2482	07:47:46	17:32:35	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6d02d86a-1b61-4b2e-8988-6739632b3231	08:07:21	17:45:45	LATE	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
0e76f85d-ff11-4f32-8309-d55a62b0f689	07:55:10	17:49:56	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2475a745-eea8-4d9f-9281-e08e0816c194	07:45:06	17:40:13	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b0b4b083-86ce-4f92-acc2-e9a50ae5cee1	07:54:44	17:08:42	EARLY	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
ee55880b-f3d7-4dbc-81e8-992ec5d0869f	07:48:06	17:31:25	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
cb986c6d-c478-45d5-ae68-a82ebbe61d09	07:58:31	17:34:03	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
d1efa062-21a1-4b0d-a0b0-883f7997fc7c	07:51:05	17:39:52	SUFFICIENT	2026-03-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
861c73dd-3404-4593-8dd1-a9fa7baf913f	07:54:30	17:36:06	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b897822a-4962-4740-b826-547cf09febf1	07:47:40	17:39:05	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
08752488-b8c6-4d1d-9821-cf465dd7492f	07:46:19	17:42:30	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
5aa3ab6b-46c2-4b27-a652-e85ed133172c	07:55:16	17:32:41	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
9c273077-b7f8-466f-8a1e-e5413ecd9c18	07:47:23	17:42:23	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
70d0f389-ff9e-4a07-9c1d-91e86fa013a0	07:45:16	17:44:29	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
4bb402f0-1684-4ab5-8de1-13a2bda28332	07:58:17	17:48:03	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
b73324e2-987c-418c-83fc-7afdb7e94ec6	07:56:42	17:33:05	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
7254051e-4016-417d-b7ea-866822c626e6	07:57:34	17:43:48	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6c4bde3f-11e2-4ba4-87ff-814ea28a1630	07:53:03	17:42:52	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
721be3c7-a20b-4e64-9d77-505c757f1f68	07:53:43	17:45:36	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
ca2bf447-0a96-462b-a80e-1fe7d2bc164f	07:52:19	17:32:25	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d6aaebdf-44fe-4301-8f18-32d5431eb7a9	08:27:02	17:34:07	LATE	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a6c0efc3-e5fa-4439-bf5a-547c815267cd	08:19:11	17:35:13	LATE	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
bbb2083b-4672-43dd-9696-de4e3110e1bf	07:47:02	17:43:05	SUFFICIENT	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
5689663a-ecd9-49c5-84cc-4510fd5f2ebf	07:54:12	17:04:53	EARLY	2026-03-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
10e2eb3d-c86f-4dec-aae7-ea47d6e85c4e	07:50:58	17:32:05	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b8897e9a-b741-45fa-a714-a36113325bd7	07:51:35	17:40:54	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
afc8692f-a029-44f0-a0bd-9e23377a8e3c	07:52:58	17:30:50	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
2c87c740-cd12-4cdb-a15e-018b67d1ca4a	07:54:33	17:43:07	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
2987c757-5906-403e-b459-bae8ea2d03b0	07:47:36	17:48:37	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
36aced03-583b-4694-bbfb-3a1141c870cc	07:46:59	17:33:36	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
58c535f4-b365-468f-999e-b0b3c643359c	07:57:18	17:47:56	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
8fb597d4-3326-4afa-91bf-3f2d9d4b94a6	07:51:16	17:42:41	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
dcabba05-4764-47c4-9c70-8343efb56d7e	07:54:30	17:31:11	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
32ed8adf-a279-4a49-aa5e-81dfdd8a3c33	07:47:39	17:49:43	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
97db1378-27d4-46d6-878d-2182b89fe95f	07:45:25	17:40:44	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
fed7c6b1-564d-41ac-b5b5-8fa74a634040	07:56:30	17:38:57	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
451545a7-4dbc-46d4-bb71-a46deaa4cb8c	07:50:52	17:39:19	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
75033f4d-89b5-4d01-b2f7-7bb7006b20a0	07:52:54	17:33:55	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
967507dc-3463-43a0-98d1-e3223144cd00	07:49:47	17:44:49	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
03223777-ba9c-4830-9be0-ccb16323015d	07:49:46	17:43:38	SUFFICIENT	2026-03-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c866f017-7830-49a3-af54-c7ff82c48757	07:48:28	17:36:58	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d6c9f4c1-da10-4379-84ef-1e2a0657de4b	07:56:31	17:46:55	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
314ce10c-07c8-43a8-aa0f-615422ab94b0	07:45:32	17:35:04	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
95f0b04c-3700-40f9-af54-f7b86ca2021a	07:53:25	17:34:49	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
cecef079-6d2b-4f5e-b4b9-302d3dfe1200	07:59:36	17:30:11	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
03672a51-8eb5-4b22-befd-850d9d2200bc	07:58:12	17:31:15	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
0f8cec7c-640d-4915-8ded-397ee0a064d7	07:45:58	17:41:45	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a33af4ff-93ac-43f0-bf89-524a678d8fe6	07:50:52	17:44:32	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
45c725ad-d75a-412b-91d7-2f47214a5d1f	07:59:07	17:30:15	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
8067a1d0-1112-4454-9dc9-742a1a2eafe2	07:54:28	17:35:55	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
3505302c-55db-4843-aa07-7e91a69d2bbc	07:53:22	17:41:10	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
c66c63cb-2a27-4776-b720-d3e0d8b0eaca	07:49:47	17:32:18	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
119fe522-d0da-426d-ba51-2d272ad84094	07:45:10	17:48:49	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
bec13a33-58f5-4887-85e1-eb3cfb8a38f9	07:51:41	17:07:43	EARLY	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
f436c1e0-287d-4ee0-bcf1-a2026ad33adf	07:55:26	17:46:01	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
e8804978-32b7-468f-90bf-af314f43558b	07:57:43	17:30:30	SUFFICIENT	2026-03-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
15e8b804-4194-444c-9946-372f8ebd7b57	08:25:11	17:30:14	LATE	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a9349bb5-b863-4c88-8bfd-ce65440f5e81	07:57:19	17:50:17	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b784572a-d039-4f23-9bfa-26d52250c7cd	07:51:54	17:41:29	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
4c8c7a36-4b06-47fc-8929-269de55bacc2	07:52:19	17:46:52	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5a10c45d-268c-4fac-888c-5d68686fd60e	07:54:06	17:30:32	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
9fafdcb0-f707-4927-af49-c20c7466b9b9	08:16:35	17:14:19	LATE_AND_EARLY	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
125f0516-e409-406b-a9a7-2f9f0f309cc7	07:52:04	17:40:17	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
8e861c81-8a6a-437f-b23a-ed65465482c9	07:58:17	17:38:41	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
50975306-7584-44b4-92ab-8d31bf7f4b42	07:59:41	17:39:12	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
23a5924f-862d-4d5b-87c4-a8dfdec7e5bf	07:57:15	17:31:51	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
388bb355-fa30-4b9a-9796-e541788082da	07:57:38	17:42:42	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
ff68c546-aa30-471f-9af8-237a4e55ccbe	07:47:46	17:30:41	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
31f1eb63-6ba5-4a73-9619-30500da7a600	07:49:16	17:43:25	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
9408046f-5545-4c00-94e5-fcf3564c5339	07:45:37	17:48:52	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
ba7a4e6a-87a0-4b89-b233-89f1a5acd47e	07:56:45	17:37:43	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
31e0514d-48a2-492c-bc27-65d174c46df5	07:57:30	17:41:32	SUFFICIENT	2026-03-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
4ed3763e-1302-4880-a24e-f5ddb714e9ae	07:47:53	17:47:11	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
8e0da7fa-489a-41c6-93d5-5a39cff47cac	07:52:08	17:38:46	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
090227ab-a319-413b-9a21-76f9d0b6f3f3	07:57:58	17:35:43	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
4473d5fe-8f27-49c6-9d19-0c7c0d4597e7	07:55:05	17:37:22	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
2d7dafc5-f87a-47c0-9a97-a206721603fa	07:58:19	17:43:50	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f2849e15-3ddd-4292-aea0-06493240d27a	07:50:16	17:48:18	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
04af560b-8edf-475a-b0d6-2d129963010c	07:46:30	17:31:55	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
4876884b-7666-47f9-aec8-4298c2632b9e	07:54:39	17:32:30	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ce28b50b-c9ed-40cb-8805-7e9fef2057fc	07:53:07	17:42:33	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6858f381-84d0-48f5-98da-2f446e0cb171	07:45:55	17:34:08	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
eedfce96-3545-4491-a5e1-317be0b7b58a	08:15:26	17:19:09	LATE_AND_EARLY	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
85cb8808-5521-42a5-9846-eec89da25c4c	07:56:11	17:32:31	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
6fcf907f-3a05-4565-80a4-dec4c7e3172c	07:47:20	17:50:03	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
3c33a43a-2e08-42e2-af58-58a73a265bd9	07:49:13	17:35:36	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
cd4c6690-b56d-4bba-aa34-ab61bc91fb00	07:52:50	17:32:08	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
833482c2-c949-4943-bd88-af89eca808f3	07:55:27	17:42:27	SUFFICIENT	2026-03-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
006008c3-ef4a-42a9-a1f1-7b70e1958cb6	07:54:00	17:01:34	EARLY	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
988f04fa-c0af-4146-b56c-f7bbf70ddf4c	07:50:00	17:40:48	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
80e0bd8d-5518-4a10-b666-86d9845a5940	07:48:01	17:30:40	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
4efef47c-b433-4b60-b583-0a039784f4ca	07:48:44	17:41:19	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e05af369-fefc-4a16-9b2c-9536eba3d5cb	07:51:32	17:48:19	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c8f58ac5-e467-47d0-bb93-02cb58fb94da	07:58:02	17:39:18	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
bd2c72ce-509d-45f6-b915-6b8b56a25114	07:53:38	17:46:21	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
11182a71-b04f-4523-a99e-bc29125787c0	07:55:08	17:40:57	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ad765ce1-c449-4fb4-8064-c2f56d8ccf15	07:57:12	17:35:58	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b7898a39-2590-4f74-8928-6d61818da2f9	08:17:01	17:37:14	LATE	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
0a8bdd08-e411-4f8d-a9c4-5234dd0727e6	07:47:13	17:30:37	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
bdddba04-ce28-4970-9b51-02edab31975d	07:46:23	17:50:50	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d0c37cf8-fae1-40f9-a591-04f0ab52e975	07:59:40	17:38:49	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
396f6d46-d326-4acc-ab17-4ecb72c99728	07:45:38	17:31:42	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
cf631116-a1d3-4691-88f4-6069e60228f4	07:58:01	17:31:44	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
c2b3f52e-1ee9-4d0f-95d0-0f2c40db48d9	07:52:24	17:33:35	SUFFICIENT	2026-03-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
9002172b-15e3-4c47-8f01-b9c22b6ce5a5	07:56:09	17:36:44	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
2fe91f4b-e24a-4150-95ef-f376808a2c1d	07:45:19	17:43:42	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
4a6565fe-dcc7-4944-9a96-b03c0b3b336f	07:53:17	17:49:38	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
431e0b78-e84f-4c58-88a1-c06ddc115695	07:51:53	17:33:32	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4e4cac21-9051-4300-8ee4-056bbd7d205d	07:46:18	17:33:50	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c34ac195-78bb-487f-9e1d-84100ce85ec9	07:48:38	17:36:49	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
1a22f0f0-7897-4218-ab84-58b540695269	07:53:12	17:41:45	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
69f9441f-9891-4547-b697-e5499addf78a	07:47:02	17:47:31	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
7c745824-7371-4188-81d3-75c6569290be	08:27:59	17:45:21	LATE	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
86422597-fe84-4b8f-b1d9-382bba8319a1	07:45:42	17:32:58	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
9536a588-e627-4234-95b3-b1228cf2815c	07:54:42	17:45:09	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
7a27c509-1b48-4fc1-843f-d0350f6b2b5e	08:29:32	17:32:46	LATE	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
be43bd4c-dcb0-47fb-9ac4-0268fd7d3a88	07:59:16	17:50:14	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
ef467f28-3307-4fa2-b703-0e47e4c897aa	07:49:16	17:44:03	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
99178bd0-e984-429c-b136-dc28a092bea8	07:47:55	17:31:54	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
97772b87-646a-4eb7-a1cf-6542237305c2	07:57:43	17:40:27	SUFFICIENT	2026-03-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
befbe777-1d71-4bb3-ae25-74f9786b8949	07:46:54	17:31:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b4f6dd07-236c-4e7e-ad3c-9ebb8f6b5d74	07:55:41	17:35:21	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
3fef1af2-9326-4284-8db2-de4288a7d64f	07:52:39	17:38:56	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
9bdcb008-31d4-4694-956b-770d1e4a35f3	07:50:52	17:40:11	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
bfd76399-8fba-4c6b-9ff8-13a138c50c74	07:51:29	17:38:53	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e0ee65e7-65db-4cfc-a256-1b077c45bfc3	07:58:30	17:43:41	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
202ecde0-2660-4465-8fc0-8caa2ab93fe3	07:47:07	17:34:44	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
b486d394-bcbf-4ac1-8fc0-39330cf7e186	07:58:10	17:33:26	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
9bea3605-9715-467e-8d35-e71b4eb6ac7e	08:20:51	17:44:11	LATE	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
18c628f3-26e5-4100-8e37-c47d98186149	07:57:22	17:49:01	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
4a1300bb-57ad-4464-9686-9a7fd17ed9fb	07:59:53	17:34:30	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b9e30be4-2d4f-4822-8839-81fd7f5ecedb	08:08:56	17:43:28	LATE	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
1d4b7de4-f202-4af7-bcec-3573d19cff25	07:49:41	17:40:00	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
c6531d73-8f43-47e2-a00f-0f4f39e3009d	07:55:33	17:48:46	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a58ed744-9752-4b09-98f5-b0b42e01861e	07:55:55	17:40:33	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3e2cbd7a-699f-4d59-ab08-1a78e261990f	07:56:39	17:33:27	SUFFICIENT	2026-03-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c30e7e11-8ed2-4cb9-af2a-491d80580306	07:48:30	17:41:42	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c4a5864e-264d-42a9-b1d1-d4947c421641	07:51:09	17:47:57	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
bbbb69aa-8e3b-4dca-b1ac-3ca4b1c708e0	07:48:00	17:05:32	EARLY	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
e7ac8349-2e06-471f-bc20-98853cde8ddc	07:58:31	17:35:04	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
f143267e-0051-423f-8753-7b29e528a033	07:50:15	17:40:17	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
3d52cb5a-d5ef-4f6f-a844-94df9bb57cc2	07:48:35	17:50:24	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
d84123bc-1bb3-4684-880d-482e8ce48189	07:48:05	17:44:28	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a5b918b5-6226-498a-8c7f-438026231238	07:52:05	17:45:28	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
926e4ee1-bfa1-4021-9051-98987f4ade51	07:52:47	17:50:01	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
41165347-5dd6-4f52-8f78-03d3fcb97bf1	07:51:02	17:47:35	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
6be475c4-a590-4934-bc1b-8cac0b1a31d3	07:46:50	17:49:39	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
91f49099-8d0e-4a5c-b0b6-4a67d0e0d9b9	07:59:32	17:47:13	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
cdbf2143-b51b-4a16-95e8-b635ef602ece	07:52:21	17:41:52	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d7487c84-9cc1-40f5-b2b1-062595019faf	07:48:54	17:44:21	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
972a794c-5c77-4b27-85d1-4525d732614f	07:54:38	17:45:45	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
6e7d9d21-2517-4b74-8d9b-cca427b38215	07:56:28	17:33:06	SUFFICIENT	2026-03-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
ce96fac2-eaab-40de-ab06-85f2b383944b	07:48:00	17:40:22	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
f220f846-efa3-4116-9008-87281bf806ab	07:57:18	17:47:33	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
593710e5-362c-44c2-b549-0771c620a2b0	07:46:02	17:35:31	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
854bb3b4-83cf-42a4-a3b6-b7642a4a217d	07:56:47	17:43:06	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
68faf29b-f6be-4790-b7f4-d6a96db74b43	07:48:12	17:33:59	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
b0083059-388e-4135-88d3-02440674dc38	07:48:29	17:36:45	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
90741b17-50b7-4e69-91f6-768e28e1f901	07:57:26	17:31:59	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
6314fbd1-4ba8-4a5e-8db3-e9e4e98f3bf4	07:55:37	17:33:49	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
65bb979b-45cb-43a5-985c-ad886dd123ef	07:52:42	17:48:32	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
46c0b4de-cf3b-433d-87ba-e1f7d5c3994d	07:52:00	17:46:47	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c7ffc85a-b385-4765-a385-d5cc97d38f5e	07:59:27	17:48:30	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a4231edf-b21e-4038-9112-b1294d4a6b5c	08:29:58	17:35:44	LATE	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
652a65ef-126e-4325-b5f9-cbf3df7451a3	07:56:52	17:34:06	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
678ebd32-2b76-4403-a778-c4cd16fa0305	07:54:38	17:40:32	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
638ab567-a7bb-4ce9-8b33-d40dc855c6cc	07:51:38	17:37:17	SUFFICIENT	2026-03-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
24f40d0a-3082-45af-8037-20e2913b966e	07:50:18	17:44:51	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
bdfcae37-6589-47c6-abd0-22848262167b	07:51:38	17:46:19	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
3da3ddeb-1b60-4e35-911f-7619c208e043	07:53:55	17:40:45	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
4e4045f3-a195-43a8-9543-aefa1cd4e45c	07:53:40	17:36:12	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
090791ce-e9ed-477d-a523-c18e416423f7	07:56:18	17:41:58	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ce2c3ad5-f0e0-44f4-b339-215d62524577	07:56:41	17:35:32	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
9b808da1-4fdf-478c-a8aa-f9ddd9b3db28	07:55:20	17:33:48	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ef355559-1d14-470f-8f63-230172de350d	07:52:37	17:48:42	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
cd3c666d-8af4-4003-a961-06591d9ec2e6	07:55:47	17:47:18	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
49fe8517-d516-419f-89d9-1b9632f4a8d0	07:51:51	17:30:33	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
122af6a3-e882-4b15-af2c-0a072d1b7ad1	07:51:09	17:31:42	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
033f2b6e-7d6c-43c3-9ed0-9319302891a9	07:49:48	17:35:18	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3b1fed72-66c7-418c-9f3c-00be0f2bd9df	07:47:53	17:31:44	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
28113fc2-2a80-47ed-b817-6259ea00198d	07:48:48	17:47:02	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
ccf584f0-4265-4a55-8a42-5c10b9276e68	07:52:06	17:49:55	SUFFICIENT	2026-03-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c2f9f8a4-a4e9-40b7-8e70-b1f5e08e8d12	07:53:55	17:37:47	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c5890302-74f2-4f97-ad64-f0d7eae1934a	07:51:15	17:46:50	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
dbb2aba3-3feb-47ed-bdf2-baeeef73c5e7	07:56:18	17:31:59	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e0c5fa72-3a3b-48d9-b357-fd1ca831833e	07:51:50	17:40:35	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c3257fb1-3f3c-46ef-b1b1-5e3573ebe07b	07:56:16	17:36:39	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f0217d00-474a-426d-a73d-c1e77146769a	07:58:55	17:44:53	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
43ebca24-96b3-4a06-9a63-9f991b525e68	07:55:45	17:50:23	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
41d14394-d5c0-4a44-a6ea-d3dda08d04c2	07:53:47	17:49:12	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
abeb66c1-41a0-484a-8df5-54930c329d50	07:48:18	17:44:11	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
17b713b3-4f2f-4a21-9ad6-f4f89f436ca3	07:49:11	17:05:47	EARLY	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b3379398-354a-494c-9c6a-609758c1b135	07:51:02	17:43:17	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
11878e5e-327a-4553-8651-83a3a1fc1a11	07:47:10	17:48:54	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
76ae667f-3104-4e89-aad0-74b063d7a0d5	07:50:29	17:34:02	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
8ee54e0c-c7cc-44c7-86c7-0e0268951834	07:50:38	17:31:49	SUFFICIENT	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f004437e-9e3a-4239-af14-d970c2d07eba	08:24:53	17:39:31	LATE	2026-03-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
57073496-3f1f-42da-a6e4-9f8c8659b927	07:53:22	17:32:50	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
db4410e1-bfff-45ef-9364-64998997eeaf	07:53:14	17:35:33	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
2c7947b9-025d-4f1a-9b80-01530aee9112	07:53:10	17:43:34	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0a23ef8e-8cca-4bd6-a00d-be809f4389c6	07:46:22	17:37:56	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
64bf697d-f61e-46ec-8a1b-575ae1b33ac0	07:50:21	17:41:18	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b5d4004f-a0e3-4adb-ba2e-eb7585125a11	07:57:39	17:46:30	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a4cdcc15-afea-47b5-902b-8b3bfbba5d41	08:05:07	17:16:28	LATE_AND_EARLY	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
10ed0c9a-13c7-4d91-91a0-ba6a804646f0	07:55:39	17:49:15	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
20b861ff-fbd9-4484-a00d-9369bbea8bb5	08:26:56	17:40:24	LATE	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d889a80b-3207-4fb8-9513-4d9d137ae2cd	08:35:07	17:42:16	LATE	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
117a9206-dd67-4b2f-bb9b-596c7fa5787c	07:49:01	17:46:52	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
277ca267-24a2-42b7-9088-dbfb14e9bb5f	07:53:51	17:46:28	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e136af35-cad2-4398-ae37-166f4114bed0	07:49:57	17:50:12	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
19240dfe-ee23-4bf0-ad31-08501d1dac00	07:46:06	17:35:49	SUFFICIENT	2026-03-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c032a09d-6049-4330-8891-acaa31d904cc	07:45:40	17:32:13	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
1932a51b-83ed-4a1d-8534-aa74838e7c6b	07:57:13	17:43:53	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
0ac96f8b-a0af-41a1-a3ce-4aa0575e248c	07:53:53	17:43:41	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
08e2e426-66b9-45b1-ae9c-01edc8c9cd78	07:46:47	17:34:01	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
afe4078d-9fe6-4367-988f-83281bf71db1	07:50:02	17:32:04	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
8a7fe478-8cf9-4924-abb5-225fba092199	07:57:16	17:47:04	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
07de9fee-16ad-43ff-97db-bc81b6e31d25	07:48:58	17:38:26	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
7df6b6e3-1097-41cf-a2b0-b70a3aa2256b	07:55:25	17:43:20	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
09111e26-deed-4b6a-a15b-c1ab557f3bf3	07:55:07	17:47:00	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
98a0051b-3ee9-41c0-b3d6-287e3ed49b77	07:54:04	17:48:02	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
11ea1476-2b59-4430-844d-3f4dc34e0148	07:46:22	17:46:06	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
c66122a0-0580-4213-beab-ee4f1e92aac9	07:55:19	17:49:05	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b227b13e-49d4-41bd-ab85-484955723c3d	07:59:28	17:42:25	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d1779209-8ee8-407b-9730-03742786a9f5	07:45:30	17:35:34	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
bef7c2a1-1395-480f-811b-26248de306c6	07:56:25	17:47:18	SUFFICIENT	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
2cdf1e69-4e6c-40af-b064-82984dc1dfe4	07:50:19	17:11:00	EARLY	2026-03-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
83d6bc91-9971-4149-b457-07662ff91d3e	07:53:09	17:33:02	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
2c8ea253-c456-4d28-bea4-40d69a478a7a	07:54:25	17:47:35	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9b783ef7-ddd8-42d3-a8e5-463dfbb8637b	08:14:13	17:41:13	LATE	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
14773d7c-4ced-4a88-963b-97f2a229777b	07:55:54	17:46:09	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
2c565685-6a67-4103-b544-72c196fc8138	07:48:39	17:38:12	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
fd174098-5aed-417d-8b7e-e3fd8e8ce597	07:55:51	17:48:54	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a63fd741-1d58-4b31-9759-6de26a6b7997	07:57:59	17:47:29	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
96fe36a9-481a-4986-b875-d0e075248ac4	07:46:18	17:32:16	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f047e42b-c71f-41ec-b712-e6d3a79a9d44	07:56:37	17:45:21	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
dbbb3e58-e104-49d3-bdff-564103e31ddf	07:55:41	17:37:06	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
cb4caa3e-6311-4241-931e-e1311df0f4f1	07:46:57	17:36:20	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
51de46ae-623b-4a64-b247-c7fe9f6e7ea6	07:50:39	17:39:44	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d0902db7-0a27-4c42-ae21-ccc2068c006c	07:54:36	17:41:51	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
2509db18-7016-4c95-852f-bdeea8139082	07:51:10	17:30:20	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
e84a016a-c96b-4ed5-9de0-9fe344e1e724	07:48:45	17:50:27	SUFFICIENT	2026-04-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f6065dee-7e6e-4d18-97e7-70008dbfe76f	07:50:08	17:40:56	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ced75a1d-6971-4ca3-9b26-908fea7590a0	07:52:22	17:39:31	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a109cca7-bc07-41f1-ae73-e457cbe85363	07:47:41	17:49:05	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
123c2b71-6ee1-4769-9139-9c8a81395a20	07:58:52	17:34:57	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
984aa540-c9cc-44f6-b8aa-d8c824e2bf71	07:49:46	17:50:04	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7b3c81d1-22c3-4d54-a4b6-3be4644f2319	07:59:01	17:46:40	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
3342823b-38a7-4ebe-a1a5-41684a17db09	07:54:37	17:42:49	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a3edc2fc-0f49-46a9-a89d-e9afa998a7e1	07:59:02	17:47:16	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
662f1538-96cd-42c8-942d-0d1865bec643	07:53:30	17:50:49	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
4a86b0df-1940-4723-8eb3-1b7052721807	07:51:14	17:48:46	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
23531fa9-0bdf-47a1-9211-e75dabd6d8a5	07:47:29	17:46:32	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
80370073-f1cd-430a-8d93-47c3b004fa97	07:50:32	17:30:42	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
4ce648d0-b6db-4392-8add-335cbc6c2ce6	07:57:39	17:35:48	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
61286526-ff5f-45ff-9d6e-ee9986574d32	07:52:10	17:35:36	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
057a6cc6-49b9-45fc-8d5a-525de1fc7538	08:26:55	17:34:47	LATE	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
efa53f71-99f7-4483-a73b-87f1c24dcb5b	07:50:02	17:37:48	SUFFICIENT	2026-04-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c6110cce-b5d7-46c9-9381-db6338a45345	07:46:16	17:41:14	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
eb9c7887-0a92-4781-b728-6cf5375da2c9	07:48:33	17:41:24	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a3873d62-9b7e-4df9-8822-6bd8bc3ebba2	07:52:56	17:31:02	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0768fd08-fc13-4b70-a347-7a0736c6959c	07:53:06	17:08:53	EARLY	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e7c1e45d-45de-41bd-8564-791daa357cfc	07:54:34	17:48:11	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d437c757-9930-48e0-a173-e457d3f46a77	07:51:23	17:48:41	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
cbbd91f2-0bcd-499c-bcf3-2e218e46ee10	07:46:33	17:38:24	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
02389f5a-12b4-40a3-95f2-e1a3bd93a7f8	07:51:33	17:12:22	EARLY	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ac535c55-140b-4000-ac73-4bca91b4720f	07:50:31	17:45:56	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
85b962b3-2aaf-4d5f-95cd-a6b7ebba8716	07:53:56	17:34:28	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
9ccbf4ad-ec3b-4332-95ba-aada65b562d2	07:46:32	17:50:17	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b63c86ad-9130-44fe-8a96-0b234b1e7837	07:47:10	17:41:38	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
23bf36d0-af62-4f31-85f0-6067ccd6b1f5	07:46:42	17:37:26	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
17b80a78-dec3-4408-a547-876e99cb9059	07:56:07	17:45:43	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
6b910986-19dd-4cf2-bffe-cd242cf33a11	07:48:37	17:35:41	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
0e0c0f20-bf71-4f22-8f6c-65b7cb015340	07:45:15	17:31:08	SUFFICIENT	2026-04-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a61b0369-2c34-4457-967d-d2910de46431	07:47:08	17:50:32	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
75d34be4-3b8c-4ca4-bbfc-1cbcb68b768b	07:54:09	17:31:10	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
2fcf0624-6104-44ee-a197-2c8c2e8060c0	07:47:33	17:42:38	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
8bc8bb6e-e1c0-4906-9715-a7e8655f0710	07:58:01	17:09:05	EARLY	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
933cf73d-8c9a-41b8-b889-57d45013205a	07:54:30	17:45:10	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7e03bf96-b5d6-436c-89ef-1e55b4065b39	07:51:38	17:34:50	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a5cc0233-d28c-4cee-a794-6c61def99d61	07:57:11	17:49:42	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
4854eb42-a6d9-4ea9-b4de-741d99c97160	07:47:46	17:40:59	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
acc51428-964a-487d-bbdd-7f701f17d20c	07:54:04	17:37:24	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
4e07848f-1828-4fab-93da-41924a9e9282	07:46:01	17:36:33	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
56056142-13be-4d04-87db-dd692e586a94	07:53:43	17:43:52	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b32c5cb3-e302-4e61-969d-60cd7fc9a441	07:46:11	17:45:57	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
5b365a6e-e686-4901-9185-6adef17b7075	07:45:56	17:47:32	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
6f5cf6c1-d7e9-4330-a768-00754988f8b9	07:46:30	17:34:57	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
489c26ec-2ec3-4f31-a4b4-ec522cfb3e94	07:58:00	17:50:27	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
5536bf73-d5f0-4b6f-a8a4-33e9c3db60ce	07:50:55	17:31:44	SUFFICIENT	2026-04-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
8c2473fd-0d94-443f-89fd-c4515d107e68	07:48:51	17:45:50	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d6c468ae-78c0-4332-9ae6-3ef60ab40e4f	07:50:37	17:48:06	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
bce8dab6-77bd-4268-8839-3a79bc7ff8e1	07:49:30	17:37:58	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
c72c501e-a01f-4ec7-85bb-b5cdc2153d5d	07:49:38	17:47:26	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
83a0a8a4-1899-4a52-974e-9ead9f452d61	07:45:45	17:30:36	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
bf2ee03d-9c04-4c8d-8c1c-66e811f54699	07:53:00	17:42:41	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ff273b2f-131b-4e52-97b8-11789395f1ed	07:57:20	17:43:23	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f55b36f2-c4bb-4c51-a0c7-e33dcd9f2d9d	07:51:41	17:48:16	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
7604a293-bfcf-4c41-b07c-b074691cb625	07:53:27	17:48:23	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
57994529-491b-480a-9612-04e91706cc64	07:55:25	17:36:26	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
1d072fb6-eeb0-4330-bbd7-8d559513eee1	07:53:30	17:35:23	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
3c4e95f4-9c5d-4b2d-84e2-a34c6a7ec003	07:52:16	17:39:36	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
136918b5-27d0-4108-82fd-6031ba5ab8f5	07:56:25	17:34:54	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
fca687af-fb3a-44ba-b38a-ee89f6b631a4	07:46:47	17:37:28	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
197bf46c-3693-46a3-addf-ff8692b8d49e	07:47:06	17:36:32	SUFFICIENT	2026-04-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
6c2d45ac-15e3-4e26-9803-cecfabd3fc2b	07:50:51	17:47:39	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
36c82a75-58b4-4b67-9d9d-4ee397edef6d	07:56:03	17:35:24	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
720f13f5-632b-4801-ae86-58106df89604	07:48:51	17:02:52	EARLY	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
e1a353cb-04ec-4775-80bb-ddadc7498aa2	07:59:38	17:43:05	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
85551f16-6c02-49c2-be03-5e3e4764e776	07:48:23	17:32:38	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2faa4a5f-170f-4d33-870e-49caba69ec76	07:51:59	17:42:39	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b740775e-e743-4feb-8d18-9ccf92e51a4f	07:49:45	17:49:03	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
6197be43-61e9-43f1-af8b-6538111871e7	08:31:11	17:45:28	LATE	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f6d97fce-5e55-4932-b674-2c17a4b9cb6f	07:58:42	17:46:18	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
d6104372-5221-414b-96cd-f4e9b455c98e	07:57:38	17:46:33	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2e1ef5a4-69fe-4a9f-bc38-a1b992642d51	07:54:10	17:31:23	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2ec0d1b7-3eac-431b-9e3e-87b9dc44e4a5	07:45:10	17:32:17	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
06fe1037-3873-497a-b9c0-7c809f01c9b9	07:50:42	17:42:25	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
0ef77ced-87d9-4c7e-8cab-18c39698600b	07:53:00	17:32:58	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
98307e86-43b2-47a4-bce5-460ac5f7fad5	07:49:46	17:47:58	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
9cc1b93e-5282-4f70-8cf1-3f0c68ccd311	07:50:52	17:38:14	SUFFICIENT	2026-04-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
41c1a372-eaab-489f-adb7-370ecdbe7c9e	07:48:29	17:42:36	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
35a718c0-9d00-4b5b-a43a-f991b8b56576	07:47:26	17:46:06	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
94245ac7-dbdb-47b2-b2d7-3b63a17eaefa	07:53:18	17:40:07	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
9eca8005-cd61-4905-b431-70e7570cc302	07:49:56	17:47:52	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
3eaef587-418f-400e-8592-36deef0792d6	07:49:44	17:44:24	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
720073aa-c0a5-4e8b-bb41-b4397905ce72	07:57:15	17:40:49	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
0d050695-84a5-409b-b623-2e43cae01c4f	07:52:57	17:48:55	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ebcebb5b-d97c-445b-a981-ebf8b1e6f093	07:46:16	17:32:24	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
0f2bb255-2389-4f75-a104-053cb7a901a1	07:48:43	17:37:51	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
134d1481-b700-4970-8f3e-2719c69ae4b1	07:50:33	17:47:00	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
b3f72915-929a-44c6-af43-d3ea13a7976c	07:49:15	17:39:05	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a1fc4fc2-6d91-4695-805a-ce9b7baf34a9	07:56:52	17:40:04	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
bd1f5941-26bf-4e94-b579-c8b80a635020	07:47:30	17:40:22	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d5152a31-ab51-477a-8cb1-3c8a66a9e563	07:54:17	17:35:47	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
374062ea-6faa-4ac0-aa99-5aa04d955664	07:59:12	17:45:47	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
6441059f-88de-48e6-bbbe-81bc121deb39	07:56:15	17:38:13	SUFFICIENT	2026-04-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
097e794b-cd61-42b2-b5fd-ed7df9bc082c	07:58:15	17:49:22	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
abf3166c-f567-456c-8db8-b6033eb0e75a	07:46:07	17:32:43	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
03eddbdd-255c-4c60-bf30-3bcd575ab6c2	08:20:39	17:30:48	LATE	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
c8ad6594-dee3-4b70-92ce-47c4db49f34b	07:45:54	17:45:23	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
ae5415fa-478a-41a8-af46-cc632e98a6c6	07:52:57	17:48:55	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2bed8756-1c4a-4056-ad1e-ee02fb85b56a	07:47:48	17:46:17	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
dcbd6fcd-83ef-416e-8fc9-f97cc682ba28	07:57:36	17:34:03	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
d0c6e197-95e3-4732-a249-4e86c2b0e33b	07:51:30	17:47:02	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
cd3256aa-b01a-4445-99f1-da1d3bc7e09e	07:51:55	17:35:29	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a8886c67-4d05-4f9d-8912-11a8379e65f0	07:56:29	17:10:44	EARLY	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c803bd54-7a60-4021-bebf-e87027ceacae	07:55:13	17:42:37	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
c9aa5181-5b76-479d-8113-ce404765d532	07:50:39	17:38:11	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
1c271c3e-65c2-4e50-8733-df08be3ac427	07:48:17	17:45:39	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a9dbe351-c5c1-41ff-b0ce-3534e46a55ad	07:47:31	17:43:13	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d36cac57-b335-4fa1-92d4-cb840be88465	07:57:23	17:41:54	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
811d4b00-c4c8-4727-bfa4-874d05e37057	07:52:11	17:48:08	SUFFICIENT	2026-04-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
1cc2195b-ae42-404b-9d34-a4ed5a3d0777	07:58:14	17:03:46	EARLY	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
5f2ceba6-949f-48a1-92b9-d1a580aad107	07:48:35	17:43:54	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
30dabe08-ae03-4db4-8bce-7aa3ad70f4ea	07:47:51	17:34:30	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
62bd73a3-4de2-4e65-99b6-b751d3cf8717	07:47:26	17:45:08	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
c5e0a604-6bcd-4513-8dd7-ff2c41c23b4a	08:15:50	17:20:19	LATE_AND_EARLY	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ad3182e5-a9dd-42c3-a040-1a5e49b42d64	07:58:36	17:31:25	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
8c4a97cb-1971-4670-8509-7c6c524441cb	07:47:03	17:36:52	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
8998ae95-f556-4f0c-ba24-04875af8b91f	07:58:40	17:33:28	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
dd55de81-b22e-4d18-9138-191beeab59a7	07:49:23	17:41:35	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
2ccb3c2f-1a95-4e18-bba7-b3c75cf4e75d	07:57:16	17:41:01	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
dff914df-5ac5-498a-9a33-d319b22d6e86	07:50:55	17:49:12	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
dfe5a8d1-c141-4212-890c-2dbc594165e8	07:55:41	17:47:11	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
093a1743-425f-4b69-b962-3d1d04ff1a68	07:52:22	17:10:43	EARLY	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
52866af1-b9c4-4876-bfa2-5dbaeb895862	07:57:47	17:44:56	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
f31ff6f3-a7c3-4cdd-8b3b-184cf8d3d5b9	07:54:18	17:44:40	SUFFICIENT	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
8eeaa599-78fd-4ee6-8f71-6d58b7e41a03	08:32:10	17:40:26	LATE	2026-04-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
bf8394d8-4e2a-44ed-8423-0d5d23de7696	07:54:25	17:32:05	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d4e497a5-94bc-4ed5-988d-79c8f4a78362	07:48:20	17:40:41	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
672a73b0-695c-4896-b69b-6eacd04c0e26	07:49:38	17:50:25	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
7a71e943-b1c7-485f-8884-57d0784c9e7e	07:52:49	17:41:47	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b8fccffc-1de1-4b0a-8eb1-537d93ab3148	07:52:26	17:35:11	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
1d03cf1a-0f01-477a-bd6f-a8af6cd9c7ec	07:47:46	17:37:42	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b4386632-c887-443b-8d58-40d4510aff3c	07:56:44	17:32:13	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
5939158b-ac8b-4aca-b159-90e3f8cf79ea	07:46:06	17:32:59	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
29e8acf6-e96a-4a1a-b485-56087848a92e	07:53:03	17:30:49	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
10db4e52-2199-4607-8ac5-e6a332f21947	07:57:05	17:33:16	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
4273f084-3919-405c-a30f-d431979f2fd3	07:46:41	17:42:19	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
08f3802b-f5d9-45f0-818d-8b4371b60ce1	07:56:18	17:44:40	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
84597fab-815d-4f0d-baf2-ef8eb8f5f832	07:53:53	17:35:01	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
6559ab8f-06d7-49a1-9d05-aaf7b6bac76f	07:50:55	17:40:55	SUFFICIENT	2026-04-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a4ba5fb0-3bf6-4113-8063-fe0e72539e2b	07:58:34	17:38:35	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c0f356b6-c038-4d95-a13f-256da7134e2b	07:56:34	17:35:37	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
d3ae1490-0caf-45f8-b9bd-40289f6a8dc4	07:55:47	17:50:56	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
756234d3-634a-4160-88ce-c7dafa22ce49	07:53:40	17:50:34	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
79424bab-a765-4482-acc2-19d8669edc32	07:50:30	17:47:14	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f9b77de9-4638-42e1-b249-0a9d319729ac	07:52:19	17:41:26	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
9da74886-ab58-41b4-b204-3567dc44982e	07:49:00	17:30:33	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ef9f42ca-ef61-4e4f-91a8-e97de976c287	07:58:08	17:41:18	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
0ed9e3ed-4599-47ca-8ab6-73586ef302a8	07:45:44	17:45:48	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
cdbaae2b-c73a-4c33-a5e3-d8ea1412dd32	07:45:49	17:43:51	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
56af43cf-ee00-4203-a241-b258b5df03ea	07:48:50	17:30:35	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
d92f38ea-7432-49e9-ad8b-21a1f794ecb3	07:51:56	17:47:27	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
eeaa1639-c6bc-46ba-b68f-8f757551c7d5	07:47:45	17:50:24	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
002b00b7-9872-4f5f-a89c-aa2beec48679	07:48:16	17:32:27	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
8e59e5cb-6a95-49f2-8ed4-16b56cf2f1f2	07:53:48	17:49:51	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
c9758b1d-1a2b-4e53-b24e-e577459c4363	07:49:18	17:50:47	SUFFICIENT	2026-04-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
960e54e7-945b-4b11-959b-358104a6d9c8	07:49:26	17:36:54	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
9d55ca17-36bd-4f2e-8945-8266caa3044a	07:47:18	17:33:40	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
3addca3d-0aa5-4731-8fd0-94a8e97e9822	07:52:17	17:49:31	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
2cf62afe-1e9e-4d6a-87e4-54ef0dc31745	07:45:09	17:31:34	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
ec1f9d61-da4e-4272-8437-d532fca2dcd4	07:46:18	17:38:08	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
4d8eb134-6dc7-49db-aff5-f639313063a7	07:56:00	17:37:05	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
54c7af71-44ea-429a-9be2-ed63e99a042a	07:52:13	17:40:26	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
12468cc8-d7c4-49e5-9e92-337be4e04b78	07:57:31	17:41:29	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
3a5fae40-2662-481e-8ba7-9afea3b88fc2	07:45:21	17:32:53	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
aa85f49a-3125-4bcb-ba15-12aec8413115	07:47:03	17:38:49	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
7bb58cce-685d-45b0-aa1c-f5acfb9cae87	07:53:30	17:35:12	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
5c9f8f23-cb5c-4767-8538-ad3f80800461	07:49:52	17:42:53	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
555d19bf-8f3f-4f46-8289-cc57aed011e7	07:57:45	17:37:24	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e2a7bcd6-74d8-41b8-b778-f8178a390d35	07:52:15	17:31:12	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
2bcc3fcc-8678-43fc-b358-d6ce7d2e2dee	07:57:06	17:46:42	SUFFICIENT	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
4bc51179-8dff-4d0d-9892-dfbbcc515f20	07:55:24	17:09:59	EARLY	2026-04-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a7103aeb-980e-4777-b555-3e352a08c1a2	07:55:46	17:31:47	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b144d186-b85b-4cf1-bb6a-c57b8cbf3dc0	08:21:07	17:38:30	LATE	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
f888c049-3c49-4675-b1b7-7ccde4d78547	07:48:23	17:31:55	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
2d47b960-92fb-41aa-9b3f-5b38c3d179ac	07:46:15	17:50:27	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
fc95d24c-1038-4842-8c32-974ff2da8f68	07:47:50	17:38:37	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
64a38572-687c-4c75-9192-dcc6df0953c6	07:57:15	17:30:02	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
03cacf32-8455-4aaa-b5e7-c76153a206e7	07:56:30	17:49:09	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ce91eb71-6fa0-4df3-8561-75b600ba2c0f	07:46:15	17:35:31	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
b2dadb36-dfc5-4d5e-8929-6b4a980a7e18	07:54:21	17:50:03	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
07418455-37c6-4e7c-bfcd-f33e261c33c7	07:55:09	17:47:50	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
34c8634c-fcbc-4de4-b88f-e6a7e26c3372	07:52:14	17:40:35	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
979297e2-6716-4820-ba5a-a20bd51b90d0	07:57:22	17:44:46	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
45d261fd-1e89-442b-8942-fa1a54c0c27b	07:56:24	17:41:46	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
0f97a080-2078-4255-bbae-53a61e596bab	07:59:02	17:45:45	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
82f11dc3-26a5-4398-9fc7-117429198ff7	07:49:34	17:45:12	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
32d7ef9e-6454-4256-bd5b-94aaf7970eef	07:53:22	17:40:46	SUFFICIENT	2026-04-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
9dbf386a-8dd2-4e28-95ee-3ae5b267c9c5	07:58:53	17:49:58	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
4d1c7c34-36f9-4fce-b1ca-36cdedb91869	07:47:04	17:46:09	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
c614e73c-13ff-491f-a380-0779244d46b4	07:58:16	17:47:23	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
285e5758-4908-4568-b4a1-e588fe7dd6d0	07:57:40	17:46:24	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
43a4170d-9ea7-435c-98ed-5e148eb616a9	07:59:01	17:49:54	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f09acf2c-7459-4b93-9a35-21128ccb960d	07:54:15	17:40:46	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f5ce53d8-b054-4c83-9705-106c6a4915c0	07:53:52	17:42:12	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
43b7aafa-5fff-4a42-8153-cff3047e3252	07:52:49	17:47:09	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
25c5e1ad-361a-43cb-8129-4670f28cd1cf	07:50:26	17:50:20	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
4c98652e-90f8-48e2-8489-0f55c6d32634	07:53:42	17:32:02	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
86885492-a320-4de1-a33d-38b2927a30d6	07:47:11	17:31:12	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
52cb7ea3-bdfd-4525-a215-fff146189284	07:48:06	17:31:36	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
936b22fb-c543-4286-af0e-e07bf8192f9d	07:51:42	17:45:33	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
97ce9006-d555-4c7f-8f87-8ca6287acf1b	07:54:16	17:31:23	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a91e9a33-746f-4522-81d6-23fbda2c9c08	07:56:04	17:30:59	SUFFICIENT	2026-04-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
61faf488-a06e-4b49-b352-c582daed9e48	08:25:31	17:32:29	LATE	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
8d57b08a-b2aa-41d2-8bac-7453518ab021	07:45:23	17:47:47	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
221dadbb-e15b-4e7b-bcdd-335d38ad0e63	08:18:52	17:41:50	LATE	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
bc98fc06-d0bb-4dfb-900c-28dda990b4c8	07:58:39	17:38:33	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
2ae6bcb0-75bb-42ed-98d8-cc2e186d89a5	07:46:53	17:39:04	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
cfe093ed-0176-4d39-8b60-828818f86b45	08:35:33	17:33:06	LATE	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
5e3cda81-d74e-47d3-8e02-ad4e0df6ed58	07:53:24	17:36:12	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
fb1ba8e1-7e25-4747-a487-175c5e73e471	07:48:36	17:50:11	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
c705e946-f35d-4a73-a7a2-a6de44fbdd73	07:53:26	17:33:49	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
dcdef86c-5e2c-4ff4-a9ca-0be301cfcfab	07:50:43	17:44:44	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
5be8da4a-343c-4850-99bd-406274e724f5	07:59:06	17:35:50	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
3be2f347-98a1-4f7d-8c21-9440713dc917	07:51:32	17:40:42	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
12e5812a-b6f9-4a95-bda5-8ba7f4536c71	07:54:28	17:41:57	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a5f1dfdc-91fe-4c9f-8d53-17f7165562bd	07:50:54	17:41:26	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
c7f102af-34f6-4621-a1ca-bc8df3b041f6	07:51:52	17:40:38	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
2fbd01cd-90d1-41a1-836a-2dbfc034907c	07:53:13	17:42:49	SUFFICIENT	2026-04-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
8a510953-65f4-4d20-be38-d138cee91d32	07:56:16	17:41:28	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a4ada05f-3b4e-49a2-8cd5-0c1035d987da	07:51:00	17:31:18	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
0e8e86ae-900b-4ccc-8deb-5c49c10c1cef	07:53:08	17:39:00	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
6d0a8dba-581e-44fb-9ff4-5635a02065ee	07:48:13	17:40:01	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
8f7a1a5d-db82-42f5-a707-b750ee453a6a	07:56:52	17:38:58	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
deb1ee84-8d41-4240-bc72-559622c81c5e	07:53:36	17:48:09	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
7cb9a860-1566-490b-9721-2549e77eb903	07:52:22	17:34:08	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
9a905eac-0588-4afb-8f24-617c7c6d24c1	07:59:37	17:37:14	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
3b3071f1-2fad-4ab9-8618-f8f572d06b98	07:49:05	17:48:25	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b9cd79a5-68d0-4135-8937-694e10771749	07:48:46	17:32:46	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c2ed60a7-c261-4541-ac53-fe076e28c47c	07:52:11	17:45:52	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
077965e3-3f44-49e6-b060-82bc0ef12c24	07:56:36	17:33:38	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
c23051fc-6bfc-488b-a4d7-0a619c553ca8	07:45:46	17:48:24	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
253ffe1f-2d5a-49ac-a5a6-1254e5317ade	07:45:58	17:40:22	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
afeea072-a507-4cbc-95d7-8876b178905c	07:51:26	17:33:55	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
b32e5645-f6b1-4aad-8efb-699440513e95	07:56:41	17:49:59	SUFFICIENT	2026-04-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
8acfb831-f219-40a5-8a8b-a41eee4f7ae5	07:57:40	17:42:03	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
423c934b-04f7-481c-993c-56781f3e9597	07:45:20	17:47:36	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
18859507-8bf9-4741-952f-9fe80061d96a	07:53:44	17:37:09	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
b27429ec-27ea-4595-9261-be18b8640438	07:56:25	17:44:48	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
f656303c-d7ca-4f1d-8bba-873eaa6cd9fe	07:53:05	17:37:27	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
5ea0d666-842a-4cef-9814-fdda3c1e4598	07:51:09	17:34:21	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
8f82f598-051c-4041-bc21-d753b926760e	07:54:47	17:31:35	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f7b11983-b05f-48a6-9ec4-76afb9b4805e	07:46:25	17:46:27	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
23a03d6b-db63-485e-9794-d793bca11561	07:47:48	17:34:30	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
f0933d7d-bf4c-490f-a593-e34df4b30ab1	07:52:25	17:50:36	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
72c31b94-2fac-49fe-8243-07c73fa3e389	07:54:47	17:46:15	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
045acff9-0f7e-4dfc-a6bf-2ed8d094a947	07:49:49	17:43:20	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a7587b1e-420a-4d52-81c4-24344df2616a	07:54:05	17:33:42	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
ce425504-b3c4-4646-8651-345e81263fea	07:50:22	17:36:20	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e1a084fb-65a7-41d1-aeaf-e6c931d0c041	07:55:01	17:39:10	SUFFICIENT	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
57d225fd-9968-487c-816e-85d08c4bcdc2	07:57:52	17:14:39	EARLY	2026-04-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
5c39371a-17a4-4052-bd43-5680a0671e00	07:45:59	17:37:12	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
64a69d60-3604-46c3-8ea4-1ba25289176f	07:47:48	17:32:07	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
526a8f76-5f34-4857-b638-e119cd89ec93	07:48:39	17:34:55	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
527e15e0-fbc1-4fdc-92f7-63c55f030447	07:49:00	17:40:44	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e4314c06-86ed-4f14-9d77-6445b7f2b14e	07:49:28	17:45:01	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7c2faebf-b5c5-4ffd-8808-8c1cc3c5a416	07:56:34	17:36:13	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
65dc8d0f-ec2c-4df9-bfb3-feb4e73c8ee7	07:57:16	17:47:30	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
2950bced-2143-409b-baf9-aeb122faa0ae	07:47:44	17:30:24	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
64eecd1e-3eed-4746-a05c-075786d1cb4c	07:55:33	17:31:16	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
abc696d5-df30-4757-a679-93aa593486b6	07:49:12	17:49:17	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
3e440f21-f0ba-41a3-a7f1-20698611cae2	07:55:00	17:32:24	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f0fa1c53-d0d4-4e06-8f58-bab4a2ce1d76	07:55:54	17:41:55	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d4227b09-273b-4509-b7b2-05cfcf0cc95f	07:49:55	17:50:24	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
639b2017-f6de-400f-b382-939a533f8df6	07:51:32	17:33:57	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
ff70d5ed-9906-449d-b121-7882ba840272	07:58:38	17:47:05	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
08b46215-fc53-4baf-be48-929039eca42f	07:53:29	17:47:59	SUFFICIENT	2026-04-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
cd71921c-8b31-4a7e-a8b5-98c4dc2b1cac	07:45:15	17:46:19	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ae41b60f-58e8-4037-9306-8ecb506d5f22	07:51:47	17:35:01	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
94c598da-7fd5-486d-9256-c92fca42ab4b	07:50:22	17:50:19	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d52fe814-7eaf-49b5-823e-e1d4dd9a85fb	07:53:17	17:31:40	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
8aedc977-78bd-47d7-8f1c-8de82c69ac37	07:51:56	17:30:35	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e0461cb5-edd9-40a2-a04e-ff3977c95854	08:12:09	17:40:57	LATE	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
06985df5-d388-47aa-8802-76d72e940bf4	07:47:05	17:42:33	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
6b93c8ca-fdee-4019-89b8-1de068b5c9ac	07:57:55	17:07:26	EARLY	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
59be8201-433c-4748-8710-4fd6f89cc959	07:47:27	17:39:58	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9aeca64b-892a-4fcd-adba-d416834260ad	07:52:34	17:34:13	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2107546a-5dc4-402a-b21b-0aee31ca1536	07:54:34	17:36:55	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f8e74376-bb37-466d-bb0f-16fdcb17e266	07:56:45	17:46:58	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
20d62571-8c61-43e0-a114-83b1716eefc3	07:59:49	17:34:41	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
3c4db1e4-189f-4f72-b5d5-8b8c066d084f	08:34:10	17:40:04	LATE	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
1614c006-7adf-4c77-ac89-49be7b3a2606	07:56:07	17:35:20	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3e03494f-fd67-4b96-a9da-216a3c1b7227	07:47:46	17:30:48	SUFFICIENT	2026-04-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
9bcc61b9-023f-4d4b-9bf4-39242fd921e0	07:51:26	17:39:28	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
4447d751-edbf-42c1-b511-033b1455ba35	07:58:57	17:50:59	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
192a964e-0b6d-4994-aa3e-57c58870185a	07:47:49	17:36:06	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d0dcdc11-7863-42a3-90aa-dab4e09cf6e3	07:45:48	17:49:39	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b2a29ce0-9dd5-47fe-b92d-e3dca486c608	07:54:39	17:37:38	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
0ca9cc61-9921-4b47-9c0d-22afc71278c7	07:55:01	17:41:05	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
537c85a9-b7e6-48ac-af93-81501ddf3707	07:52:08	17:46:54	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ecd49454-8a85-4eed-b10a-35282b963e74	07:56:41	17:41:11	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
c29662be-dc31-447d-8dd1-81def00eee5f	07:52:30	17:34:10	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6a9eb626-f2df-482d-9016-c4abedc3e2a2	07:45:26	17:30:59	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
35884fc0-3055-480e-b87d-62ab93372cee	07:51:14	17:36:48	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
003aa109-6461-4f6d-951a-16b3e0ac6b1f	07:47:59	17:44:55	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
2b22e592-1ab9-412d-979d-dbb92ebdc593	07:56:20	17:44:56	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
cbb5eaad-0267-4d68-8830-34f8660cdb31	07:51:49	17:31:38	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b0d4a1ef-6660-45a3-a3c6-5e8f2d4096cb	07:51:46	17:40:25	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
1044d898-39fa-4245-8028-fa0da1187edb	07:56:36	17:49:34	SUFFICIENT	2026-04-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
fe3fbf6c-986d-4713-9824-ed676ec38e6a	07:59:45	17:31:33	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
9103a015-4d45-4aec-9f02-2bd5531b1fed	07:52:52	17:31:56	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b8e8530d-01f7-4d91-8c27-24fb41eba85a	08:17:47	17:06:35	LATE_AND_EARLY	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
40d63f16-9c45-4139-909f-4532ab5ed67f	07:57:40	17:31:12	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4e1b4c72-e2b4-4f21-b684-6de585535b9e	07:51:56	17:39:49	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
cdbc15cb-822a-4afb-82ad-6933995917de	07:52:10	17:43:18	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f48626d6-c7f6-4dd9-aa2c-9ccf282df937	07:45:44	17:46:57	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
964fe14e-ea1a-4c87-8941-80e07c0dca57	07:58:41	17:44:05	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
07db303f-4c95-4b24-884a-0d4d4732284b	07:46:11	17:48:57	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c5f937c0-dd59-4521-a08b-5aa54708d23e	07:47:25	17:43:20	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c92197c6-9ba9-4740-b8a2-3cc80575f1b3	07:47:29	17:48:57	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f161af3f-8f4d-4bb1-9c77-0897702395c5	07:48:56	17:44:05	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d1b546ce-d907-482d-ba0b-a483fad769bd	07:56:41	17:35:45	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
7d0ee2e1-1c5e-424c-9796-60ef64c78fd4	07:46:07	17:44:40	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
3cc7e94e-80d1-4e54-ba0b-e8cff59746b4	07:53:45	17:42:46	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3addd5ed-3627-40a4-af22-5117e3a55066	07:53:39	17:35:24	SUFFICIENT	2026-05-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
6796abf0-66fa-441f-ae09-74a0a30f0a78	07:45:49	17:35:58	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
0344fdc8-131e-44ce-8dcc-e1782223afea	07:58:42	17:34:10	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
ef1660a5-cbee-4fec-9b0a-366ef00eb9bf	07:47:49	17:31:26	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
b23cb69c-54a9-4e45-9f74-97bd19232b8e	07:56:49	17:44:18	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
6b717f96-2a3e-4ff0-b22a-3da2fff0e3f8	07:46:57	17:34:12	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
0f140e09-df51-4b0a-8d98-ef16279da9bb	07:57:16	17:30:29	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
5914ac3b-1fbf-412e-8247-bfdef77c260d	07:52:34	17:30:38	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ee5590ad-ffe1-45b3-acbd-8bd70d80b2c2	07:48:13	17:48:42	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ae1849ff-feb0-40ad-b52b-5a5ccc3f2d6b	07:51:28	17:32:38	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
8dc77dc8-8705-413d-9a4c-2bd92a1b1537	07:48:56	17:47:17	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
fa6362c9-3e9a-49d2-9bd3-05331a5bb746	07:53:52	17:36:03	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
60dcbda1-77ce-487a-b3c0-7839de3c5a68	07:45:41	17:41:02	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
fb27914e-e198-4585-ba88-cf173af0a360	07:45:42	17:48:53	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
9aa1877f-4253-47dd-a081-34957c72214d	07:50:58	17:32:03	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
c7119580-8bf3-4f85-ae20-0cdc9decae51	07:47:10	17:39:39	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
d34b84e8-02af-44a4-9e02-a5be26b1df8c	07:56:38	17:48:50	SUFFICIENT	2026-05-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
ac5362af-0179-4989-97ad-e316dbddbb79	07:52:47	17:48:23	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
3e838135-1518-4671-bab2-fe24fe9d5620	08:07:49	17:39:20	LATE	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
ffc2ca45-90b4-408f-8a1d-5a278fbcda66	07:51:52	17:32:48	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
abc7a79b-8260-408d-88b0-c0b457976cfd	07:53:04	17:39:30	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
39dad19b-5eca-46f0-899b-ab00790e8624	07:56:55	17:38:21	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
371181a2-d69b-442d-8ae8-853b19f76f7b	07:53:13	17:36:39	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
9d053feb-9de7-44ec-bb05-1676070fe2e4	07:54:46	17:50:33	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
5cc7dc40-609d-4e43-8da5-4a0da1dfe7f8	07:55:46	17:09:27	EARLY	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
bf836f4d-10fa-4746-a9e9-52a38237b3cd	07:50:16	17:46:36	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b22b188b-109a-4ea3-837a-f34b050c7dce	08:16:59	17:09:39	LATE_AND_EARLY	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
54e73bfa-a8df-4e01-9eb9-8e63c37307ac	07:53:46	17:50:31	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
7ee17d61-9974-40ad-a99e-e2408cc90f87	07:47:56	17:49:14	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
1a012cb6-7f1c-443d-b983-f8ab8a11b665	07:48:00	17:33:01	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
6fb20fb1-1365-4e7b-a6c0-46e05b7070af	07:57:07	17:36:51	SUFFICIENT	2026-05-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
b35a591a-24f2-4b83-b6c5-5995ccb8e03f	07:51:26	17:31:21	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
07a82813-3280-4953-a683-783ba9ed1447	07:57:40	17:36:00	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
2b1436d4-41da-4b80-9f85-88607aca4fe8	07:56:18	17:38:50	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d12ed3ba-4e6c-4fbb-a50e-311aa2037796	07:49:32	17:47:20	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
17549d71-ebda-4cab-8df7-75c843b90cfa	07:46:43	17:40:21	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d5e6582c-21fa-4c36-8b16-f83105fb221b	07:54:39	17:30:53	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
503698ab-fa93-4338-af2b-f8071974631f	07:50:53	17:40:59	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
aa123441-cde6-4b12-a1bc-be85af9051e7	07:59:30	17:31:41	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
305e68f8-7e3b-427c-8b8d-df0f108dae99	07:47:40	17:44:57	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
d696aaee-e597-4232-970e-306ceffc3ed3	07:59:21	17:44:50	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
92c6d559-67e3-46c6-9cd7-6e1d3c06f000	07:59:47	17:31:53	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
fe84ed43-ea5d-4e0c-8f1c-2e205a266143	07:54:46	17:40:35	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
285a2a21-a75a-4e28-80c9-6538bd5aa1df	07:48:36	17:40:51	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e266c05c-0d1f-4640-8a5f-bffb59b9d66f	08:30:22	17:32:09	LATE	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e2c0a545-d0f8-4337-9c6d-07bffd1556bd	07:45:21	17:42:40	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
4a2b274e-f353-4da2-837b-2a797a3f9660	07:47:36	17:49:24	SUFFICIENT	2026-05-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
35b0ac7f-8305-4b16-8e06-52fb4373d0ab	07:46:55	17:39:45	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
570a1ad4-e3a3-44f4-b580-07d5cdd0e73d	07:56:02	17:38:26	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b96f6684-e2b9-476e-b36b-175e1fdcb2c3	07:59:15	17:41:28	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
98552afe-d94f-4ed0-9964-bbe6f5fbed4c	07:49:13	17:46:19	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
51aa6c77-7131-424c-866c-347cdd9cb218	07:50:50	17:31:49	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2042b65c-db1d-40fe-8269-4810c6f33025	07:46:28	17:46:01	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ef2e690b-62f6-48c1-bdd9-71ad86943bf8	07:59:32	17:34:12	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
c55806f7-c8eb-4c43-9eb4-753e2462146b	07:52:46	17:46:19	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
42424709-2c5a-4a4c-a14e-941e781b3662	07:47:49	17:33:52	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a7429082-5bed-49a2-8165-6bc954bcfaf4	07:56:43	17:04:13	EARLY	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
cbed1d0f-8c4a-4ebf-9601-bf307b3cbc19	07:52:24	17:46:07	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2bd70f28-e501-443a-b34c-7473e9df4148	07:59:02	17:49:55	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
85bb9089-a057-433c-a363-a8be7cea27e0	07:52:56	17:31:06	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a6ec4a94-af5b-4cbd-a8d3-f54fc476221b	07:55:47	17:39:01	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
59bbc1a1-f736-4bca-bc93-c17cf03d1bea	07:49:40	17:36:20	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
41297412-407c-472e-a4bc-16acdc43b756	07:49:17	17:47:20	SUFFICIENT	2026-05-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
d72f196c-f4d9-4b5f-b6fd-4525e226281f	07:55:07	17:38:09	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c0abecd4-3ea6-4308-9334-5c2749840c59	07:46:00	17:49:35	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9f2c1935-7ab3-459a-b964-641b5ed207a1	07:48:34	17:41:35	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
718290c7-1025-456a-a901-58383cdef18b	07:47:45	17:39:36	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
cc2f5acd-f6ed-42ca-b254-859b77ae1627	07:46:19	17:49:57	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
1ebd781f-e682-4cd5-8bf8-bcc665b31420	07:52:03	17:34:01	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a461e775-57b2-4832-bfba-4e705d266651	07:55:03	17:33:24	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
755fcf3a-45ff-431d-a717-88090227190f	07:51:25	17:35:45	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
6d0f0d2f-d521-4bf7-b8b9-b5931ffdbc2b	07:54:40	17:44:39	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c0360a82-6c5b-4e73-833c-48481db29365	07:50:52	17:36:45	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ee654be3-94e1-458a-829b-492e95eeb367	07:57:34	17:32:59	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
38e5c512-45af-4657-8d1a-44ce9092d3bf	07:52:36	17:34:05	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
2ef7dc5a-79d1-4373-a396-dd549f8c3b6d	07:59:44	17:44:06	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
616fc7dc-c168-4544-b3d2-69eb3c43a1f7	07:55:41	17:44:30	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d8f941f2-9be8-4860-b550-3ac02fde4d65	07:48:09	17:49:16	SUFFICIENT	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
4d22efbf-b032-4ec8-9155-2c32911b9e07	08:17:11	17:40:50	LATE	2026-05-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
023fef14-330e-4273-bad3-fd599af7c35b	07:50:29	17:45:01	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
5a6de5a7-bc05-4e0a-a00d-47a7ec32d7f1	07:46:22	17:45:29	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a1f069b8-8289-4bcc-9b4f-513e80a04c25	07:49:49	17:41:38	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
1232f03f-43e7-4160-883a-a285ba295b44	07:53:06	17:42:52	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
de0cb7f7-db72-4955-a557-d59a698398eb	07:46:20	17:47:41	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
aa01bd5e-a417-4557-be24-f0f6380a0f0b	07:49:34	17:44:25	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
c604189d-367a-4215-b12b-05833025b034	07:48:39	17:37:35	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
57fd1011-f3d2-403e-8561-263d4b94b574	07:52:24	17:32:21	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
b6340337-8627-44b3-8c09-1d98f28f65b7	07:56:37	17:43:50	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9a14b27f-6d24-4783-8d19-17da2466acb6	07:57:50	17:10:34	EARLY	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
cbabef5c-e582-49c2-8aa4-4ea3f89026b5	07:47:42	17:32:47	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
0592496b-89ea-4c53-93e9-26e8ccc9590e	08:23:53	17:45:07	LATE	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
c61420d4-63a0-4ffa-9746-d5659d0e8a31	07:52:20	17:47:06	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
5dfaebe7-7a2e-4f3c-8288-fee55ca4a25c	07:47:19	17:42:04	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
689b6c5d-7ea3-4f6b-9710-9729b1d15c15	07:55:52	17:49:49	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
83aa6ea6-52da-455e-96e0-531ac7a5a65e	07:50:31	17:50:42	SUFFICIENT	2026-05-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
eedfe17c-e60d-4a43-b3b6-040cf711aebd	07:48:52	17:34:56	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
8fc0ffad-2bc6-4049-97c3-659fec7ab7f3	07:57:40	17:30:48	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
7731affe-1036-48b5-a03c-781977b028e7	07:47:28	17:47:18	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
17176851-537d-4285-935b-66462e0bd8ee	07:54:28	17:36:13	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5bfafc99-b2a1-4cd9-9136-f70283269dbc	07:50:19	17:48:50	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
379917bb-6f7f-4441-b8f5-7690f72bd60b	08:14:58	17:43:45	LATE	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a3a8c663-2ad3-484a-a573-9aa305e0c41a	07:53:05	17:00:39	EARLY	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f7fd4d45-6fda-4193-8901-249ff34bc4b1	07:54:54	17:04:54	EARLY	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
eaec24e5-19f3-4fa2-a0f7-aa68507b9abb	07:50:57	17:47:03	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a749d43e-a782-4556-b26b-2a2464375895	07:53:52	17:41:07	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e8009a23-2789-4b91-aa45-fab5b9ec571c	07:58:01	17:37:27	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f85593c6-de6d-4455-8d1b-02e03fbccfc8	07:51:40	17:40:45	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
1018861b-137e-4241-ae40-3303e43dbce8	07:51:27	17:47:13	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d85e56ed-0b42-447f-971a-91e14cfa28b6	07:52:08	17:36:35	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
49b1ef4c-1974-4d01-acaf-efe36aa2fc96	07:59:23	17:43:09	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
4032e852-da3e-4ef5-a0c1-b2cf4bbd7ba7	07:58:42	17:34:08	SUFFICIENT	2026-05-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f244f5e2-c680-4fd1-885c-0bfeec32a527	07:55:01	17:34:46	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
9ded38f7-b61d-40cb-8706-5de526cc35e2	07:55:27	17:34:05	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9c82d990-e318-4a18-9fb7-384ac1079418	07:57:26	17:44:57	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
f7f9fbdd-7e18-457a-b1e6-76bc1633d2a5	07:54:59	17:43:39	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
28ab04cc-fbf7-43ee-9665-28385718dae3	07:53:27	17:47:52	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
6ccfb323-068d-4f33-a195-7a82f8d1f96a	07:50:14	17:35:27	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
1b87b86f-2d93-4d50-8c7c-786757ae9a41	07:54:31	17:37:45	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
bea6aac2-53e5-4193-bfbd-d651a4e99ebe	07:51:59	17:47:36	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6970eb66-86fa-4772-b1c1-1fde34d0ef07	07:45:36	17:45:45	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
16c5f42d-8e80-49e2-899a-47eb57738431	07:54:30	17:32:09	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b1e2678a-e04c-43d3-945f-68ab1657c390	07:53:54	17:38:29	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
7ea869af-a143-42a2-bb91-b1a2f91eb218	07:53:56	17:49:05	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
dbaf7319-f6dd-4430-8a9d-2217067b1694	07:55:47	17:32:43	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
29c0c42d-73a9-473e-a30d-fb904c794fb9	07:57:37	17:39:39	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
0e82cf3d-a529-450f-89cd-d3b3e7dc8252	07:50:34	17:30:30	SUFFICIENT	2026-05-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
7f1aff3f-3223-43c5-b807-e760c9ee3554	07:59:30	17:48:46	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
1be883ee-a29d-4f70-af95-09ce1185c473	07:50:51	17:39:18	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
0c44e275-0599-489c-a825-8c9c28b42e44	07:56:59	17:49:47	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
f5a73732-52d6-44e5-82c3-0496560d84fa	07:57:36	17:38:03	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
d87732b1-74da-4a0c-b7f4-c20b4a1c5bd0	07:54:10	17:48:03	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
c0f501cb-fd84-4cd6-a57f-f3e04f36fd92	07:49:51	17:49:01	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
6afe2edb-77e9-47db-b8ad-638525cfcdaa	07:46:08	17:46:04	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
c5ca7f80-889b-4102-97ec-c6210fa5cfde	07:49:16	17:34:39	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a1fadf6c-c028-47ec-a28b-d53611b1d9b6	07:58:16	17:30:47	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
f177e3d6-cce9-4e1c-9bcf-b8c04e981106	07:47:58	17:48:47	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2aa0576c-a5c4-4324-b315-a360df345119	07:52:23	17:35:16	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
7d706d30-8fba-436e-bfa3-1463f95de4be	07:48:31	17:35:51	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e7c45d25-646d-4f24-b996-02ee09f7b3d8	07:45:21	17:32:09	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
00f51304-9435-46c4-8039-4ce9bc32dd47	07:58:09	17:45:48	SUFFICIENT	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
ce45d6dd-eba7-4560-a5e1-5569b1a312e0	08:17:15	17:19:46	LATE_AND_EARLY	2026-05-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
3a5b7ff0-c0d7-43e9-840e-5d79a158ddef	07:48:36	17:41:03	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d4735489-fe3c-4571-81fa-6928950053e6	07:57:52	17:33:03	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
da142f89-0abe-496f-ae02-1816ad04aabe	07:51:30	17:39:30	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
4f1e4f7a-ce62-484e-911d-db176dcc2828	07:57:59	17:47:14	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
14aff16e-751a-401f-aecf-fb747375764e	07:56:24	17:45:16	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
429cd2fd-fd3d-4442-a293-763e63b96cac	07:58:27	17:30:18	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
cdabc6d7-72d1-475d-85db-1c7facbc6045	08:19:24	17:40:33	LATE	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
47a633f2-aa11-48a9-a679-1e47981219b7	07:45:06	17:47:40	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9106b35d-27ec-400b-b1d7-334f986c911b	07:58:27	17:49:58	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ace46255-9fe2-441e-b105-c2ecad58feb0	07:49:21	17:38:17	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
fda9f047-8c5a-481c-919e-62243c1c4190	07:49:41	17:48:25	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
f9207a64-2b16-4222-866f-4cf587a4bec5	07:55:47	17:37:46	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
9c9acf6c-89d5-402c-80f4-62e6320b8a19	07:57:12	17:46:21	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b2eee430-e933-4a2c-b481-c31cd2eae30a	07:47:20	17:47:00	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
688db55e-ca34-48c9-bacf-d427e8040af1	07:58:04	17:30:26	SUFFICIENT	2026-05-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
8a61eec2-3c5e-41a1-90eb-3cc314f1d3ea	07:46:43	17:44:22	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b4ea7072-0a5d-415a-92b3-215259205ad9	07:49:16	17:36:02	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
6c45ace7-ca37-4eda-a204-933907b91468	07:46:03	17:49:42	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
975ff199-fcaf-4c08-bb52-3d03c6738d1c	07:48:38	17:50:07	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
bfd3d055-f995-41e8-85fb-c6f91338afb2	07:46:05	17:49:08	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
6446b4aa-fa3b-4b17-84b1-7b779d753038	07:57:57	17:50:36	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b96bf0b1-c1e8-42c7-8134-89031d90b8bb	07:47:57	17:33:44	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
494eb965-b0cd-4e56-8349-770a8432a3d2	07:49:29	17:32:40	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
d26acaf4-1c94-4368-895e-521d53562549	07:49:49	17:43:44	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
df83cde6-0a50-4d2f-a177-def6ca5a6432	08:29:49	17:40:16	LATE	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e4ec37e7-d2d4-4a9d-b4c3-80d9b76c1307	07:46:17	17:31:24	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a6c6e40d-8c20-4744-af55-0c329db8912e	07:45:16	17:38:11	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
98bfa952-e963-4368-b692-85228e775df4	07:52:59	17:36:39	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
25181d4d-6f50-4f55-903f-597567eb5c28	07:55:31	17:33:09	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
522e3268-b7b2-4765-88e3-43d6d64ac8a5	07:51:13	17:49:41	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
cc062a10-1814-4556-9a67-2cc37c60997d	07:52:45	17:38:06	SUFFICIENT	2026-05-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
001b7548-fc80-45b7-a790-7c389f401a60	07:46:36	17:38:49	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
e64f53e1-0ec2-445c-88e6-f8bc81348409	07:59:31	17:34:41	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
d9aef89a-6f5d-4eee-b5a0-03dd73fb49b6	07:59:02	17:42:17	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a86372ff-61b0-4af4-8c2e-7391fa4bacca	07:50:57	17:42:36	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
cc6db644-071e-473d-9282-394536ccc02c	07:56:49	17:45:30	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d16235d2-506c-42d1-9382-33cc8bccef31	07:58:46	17:32:34	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b224f6ba-1af3-4f73-b4e7-17bbf3ad175b	07:51:44	17:45:07	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
7e4fc083-653f-4f16-9f59-84c636e29448	07:59:22	17:40:43	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ed09eaff-04fa-4363-af51-edaa05227826	07:45:40	17:50:05	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
081afcca-04e5-4074-b5cf-fe2b2311b8de	07:58:21	17:32:53	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
dabce7d1-5faa-434b-9c0a-37af08fe046f	07:57:18	17:50:12	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
135910db-8ed5-4dd9-9a01-225a10b1791e	07:45:24	17:36:19	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1a978582-ccc3-42ad-8559-f812ec2299d7	07:59:06	17:50:44	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d285325b-f922-48ac-8319-4b58e98c559a	07:46:56	17:50:28	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
6256decf-edef-47aa-add3-50c6b5505dee	07:47:02	17:36:01	SUFFICIENT	2026-05-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
6965f4c2-dd89-41c4-a4bd-0249d444bfa3	07:54:15	17:45:24	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
6fb7fbcb-a8ff-4329-a0fb-cb277eb5ccde	07:53:41	17:39:31	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
748f93d4-510d-4a74-a807-1a331294be59	07:58:51	17:44:01	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
c40ec36c-286b-4810-8cfb-779d243ccef0	07:45:21	17:31:25	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
dd002481-506f-4868-ae8d-57b4892cc93d	07:57:41	17:46:29	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
4c1a38c1-a251-4ab9-a3ab-2240ebc0d53c	08:32:55	17:34:47	LATE	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
1c54ed0a-0e80-4340-bc74-d0725c8ffaab	07:59:04	17:31:47	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a65803c3-d6ac-4ea3-bc6a-4584ea00e724	07:55:01	17:45:58	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
77e1a68c-f29d-4fbe-b77b-5b2b659faa53	08:06:15	17:34:00	LATE	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
82f83caf-04c6-463a-b5f0-2a3658e43775	07:45:57	17:39:52	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
1c20523f-e51a-47af-9b11-5453397c7f07	07:52:39	17:35:53	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
28e55ad9-f50a-4826-94f7-dfc77518d4fe	07:58:52	17:33:07	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b9ecd495-f361-4a8b-87be-f691297625d8	07:57:39	17:37:04	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
733dbe53-8f9d-4c4c-9cae-02250a3e1ac9	07:51:21	17:42:20	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
c64cfd56-3e46-4b55-b609-6e99d268f8f9	07:55:36	17:47:08	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
656099fb-05d8-4e2f-9999-1d1347281213	07:57:13	17:31:37	SUFFICIENT	2026-05-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
b886b304-d932-4e27-8586-8060c45bbb70	07:46:07	17:38:09	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
dc9b680a-6399-4809-b9ba-e33a96f86968	07:47:44	17:41:35	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9b0f4f66-6bb5-4808-ae1c-d818e11a1e36	07:48:59	17:48:02	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
01db4cbe-4113-43a9-9ad5-ee60d44cd9f4	07:57:54	17:50:39	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
7522a247-b3f9-4c93-9beb-d819a767ed18	07:47:01	17:45:05	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7c44a9f6-b581-4ff6-ac72-8a1af30df0c5	07:47:59	17:32:45	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f8916cad-fecc-4cc2-85fd-49f21f9a5bad	07:59:18	17:43:44	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
9e2d0077-4a64-4009-8a96-dd84616cfb18	07:57:30	17:34:13	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ba549166-cb08-49b7-aad8-eb0341fa2da9	07:49:33	17:44:26	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
4b95ccc8-1ae4-4f2f-8d64-58cc08c6722c	07:47:39	17:31:38	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ceb6f369-799c-4a6b-beef-4a14c070f2d5	07:52:39	17:32:40	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
52b269cf-bc3c-4a66-94e6-8483f9c13ddb	07:49:22	17:43:00	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
35d9e8bf-a885-4ead-81c4-62478710983a	07:48:07	17:46:06	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
f238e756-ba0f-4ae7-8ce2-a7411ce6bfc8	07:58:48	17:47:32	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
c8db5901-ee69-446b-a71f-11c00906ecc5	07:57:40	17:36:17	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f7c68d4a-39b7-4c95-84ba-e9dde72e5796	07:46:50	17:34:43	SUFFICIENT	2026-05-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
56efa970-87cf-4860-ba43-d0ddf8272ccf	07:59:30	17:45:11	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d195e8ac-6d77-4d6e-b00c-5349a7f0043a	07:59:02	17:31:41	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
7d8b877e-e295-41b9-99f5-ed1e962eb7db	07:48:27	17:38:21	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
894a8ccf-3b18-428b-bf7e-581e434e4f58	07:59:48	17:44:02	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
9fcb2d49-c912-48d1-bc13-a3ae5ca07557	07:45:59	17:47:11	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
0bfb95ee-0960-4b71-99ab-b44c2a2d348b	07:45:31	17:46:07	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
04dbf49c-207a-468a-a208-0ca88fff42ba	07:48:46	17:44:37	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
414b128e-8f4d-4d49-9690-b0c1c90257ee	07:51:12	17:40:14	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
c961346a-6d6a-4764-a20c-7b75210bf124	07:50:14	17:33:15	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
fe29a323-92ae-43ad-98fe-ac1604b99a85	07:58:12	17:42:57	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ebf3e011-dd38-4dc4-b62e-a9500fc2a140	07:52:37	17:45:03	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
0de11bc1-b1c2-44ee-b2fb-9011efb0a618	07:47:13	17:49:29	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
f3c19f31-b0d0-4549-89e2-3ea5eaa4793a	07:50:08	17:44:46	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
27685ba2-07c4-4442-aabf-9a897d3abdd5	07:50:17	17:36:21	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
24fea2f4-5c19-4e92-bc3e-7e6cec1c7be8	07:56:36	17:31:17	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a3fc3847-6080-405f-a44c-497866e4d44a	07:58:29	17:44:26	SUFFICIENT	2026-05-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
e0b5119b-3471-45f3-b142-7893b74638e7	07:50:14	17:39:38	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
0ff14888-3c11-4ab0-821d-faf24f896aa5	07:57:40	17:49:57	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
0d0a04d6-7fd0-4811-bae7-7a6df4c19bc9	07:53:54	17:37:05	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
8a166485-71c5-42cc-81d7-f0977493308f	07:53:31	17:36:37	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
eb96097b-18f3-47d8-85e8-cde6c9904378	07:52:17	17:30:46	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
8a972b99-7181-4eec-b09c-efee1eb84bbc	07:58:15	17:37:20	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ea3e9ffb-9145-4b0b-8dfe-8d04b2e39502	07:48:57	17:48:09	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
dd86ac02-1906-4575-a066-f7a04e2e6f52	08:33:00	17:43:02	LATE	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
3799b186-d152-49fb-b401-f94582eab85d	07:52:46	17:46:02	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
bb716114-5973-4ee6-a47d-291ac759a956	07:51:30	17:33:28	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
8230a7ed-be64-45d7-8a3b-551e73f3734e	07:46:35	17:30:44	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
ea502333-2504-448b-a504-acc1a99126f3	07:48:08	17:41:18	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
ac230981-8382-4d6e-a1b6-b636c8596585	07:46:01	17:45:42	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
c75f5b8c-b6e2-49c0-ae1e-5e289918460a	07:56:29	17:48:47	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
8411c298-8ee8-4c56-873c-0e517532c8b4	07:52:29	17:34:55	SUFFICIENT	2026-05-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
d2359ca5-d8b1-4cc1-b29c-d43035ae1956	07:47:50	17:41:40	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
5be9b4fc-846a-4617-ac1f-06d75f0b61dd	07:55:00	17:50:04	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
f8e20382-5b71-49cc-89d8-9ad0878d0f53	07:56:21	17:46:02	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0f33d918-c069-4d4c-9757-087ebb2ca196	07:57:17	17:49:34	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
91eebd05-2c86-4291-a29d-a88c53d4f9b9	07:48:50	17:32:39	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e8dc1040-285d-4ffd-ae2f-a643e8d4a6e7	07:56:59	17:31:32	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
38cc8e08-469a-4b3a-a800-7871f8815946	08:26:23	17:31:07	LATE	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
0bf0cb19-bc40-4d6c-8319-7cb01c6c4f52	07:52:39	17:31:23	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
583304a3-ad0d-48d1-ac80-202fa2da7712	07:55:35	17:32:35	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
557f6444-5a49-4ff8-86ab-862dfa1098c9	07:48:08	17:40:15	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e8d3f639-83f3-45f9-b131-6f50b8f3d4e0	07:55:30	17:48:55	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
e4bba81c-51cb-4b3e-95ad-2022e301d6f1	08:11:48	17:37:20	LATE	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3a835aa4-793e-489c-8acd-6e5fb9021144	07:49:32	17:43:17	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e9397278-b74b-4c9b-9423-8e9737d72e6f	07:50:22	17:44:31	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
6e52c0d9-4622-4dc8-84bc-3b73cb022761	07:58:07	17:45:45	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
8c9131c4-9e2f-4424-9abb-a813f12bba20	07:58:34	17:39:28	SUFFICIENT	2026-05-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
21e2aced-b204-4a07-8fae-ca4d2126967b	07:57:43	17:32:12	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
fb7c0fb0-eaa3-4d2e-9a5a-21f3ca6cdf14	07:52:05	17:32:25	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
bd94e163-4985-4b31-94ab-86bc6d458691	07:49:04	17:33:10	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
ccbfaf73-bbb4-4ad0-8192-f8f14d9ee338	07:56:09	17:45:09	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
05b8d3ae-4227-4ed1-8cff-daecceca4968	07:53:40	17:30:18	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
10bb98d9-0501-4442-9e74-db43ecc0de82	07:55:34	17:34:30	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
2243ad86-541d-406c-8fdf-e69793cc31eb	07:52:47	17:50:01	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ff815098-d17d-41c1-8cb5-30beaec0486c	07:46:01	17:37:53	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6f34080c-3edb-4ff9-9fd1-da05487fed19	08:25:21	17:43:37	LATE	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a5b453ec-646b-48e9-b29a-ace4cb37c60c	07:55:50	17:40:31	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
18375435-5c9e-4f09-a8f2-fa906a9bc77e	07:56:33	17:47:28	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
ff914487-31c2-4423-aa40-17edd55666ec	07:54:08	17:39:10	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d68fcfe6-b732-4fac-83e2-44b91ee6906e	07:48:30	17:41:18	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
85592733-710e-4b77-b962-bad69888c3b7	07:45:09	17:41:18	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
252e3733-e887-4b58-9511-1e4d33064450	07:47:39	17:35:45	SUFFICIENT	2026-05-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
6b87af44-1842-42e9-b4c6-6e3a04e2830f	07:47:11	17:34:10	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
38d842e0-88c9-421d-9fd1-8857dca50914	07:45:20	17:48:08	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
20c518e2-f2f0-4e7f-a82c-d40872d445dd	07:50:11	17:36:35	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0a9eba39-d0ba-46d3-a3b0-392d492ff84b	07:55:20	17:41:09	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4c0e360d-a19c-4226-bddb-86a753770b6e	07:53:10	17:47:19	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a256bb3c-410c-497b-a237-7744d40677d4	07:45:25	17:45:49	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ded48de7-ab2c-4160-bd1f-216f4f781f09	07:52:59	17:40:09	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
16cf214e-a7bd-45e2-ba6e-63c26259dd76	07:56:34	17:46:21	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
4795919b-6e9c-493a-8fef-d4c6784502da	07:49:30	17:39:48	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c913eab2-fccb-4591-8539-3d43fc720bfe	07:57:42	17:04:51	EARLY	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2ec2e3d7-fb66-4645-9957-2be6caf867e9	07:59:59	17:44:21	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a722398d-878c-43f2-9641-04352eded140	07:56:30	17:31:08	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
7898f794-6d64-463c-a72b-0cf187287594	07:46:19	17:30:25	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
10323426-be23-49b7-aedd-2d553b0334e7	07:48:28	17:41:05	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
b499ad72-78ad-446c-8308-3a9d47a74cf2	07:54:41	17:36:37	SUFFICIENT	2026-05-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a8cf4b1a-2d05-4ef3-ab9e-a0ad9684c480	07:57:59	17:38:12	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
4d4d1eeb-6fa4-4aa8-b868-b6d02ccbf6ce	07:53:54	17:44:43	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
26d8dffd-163b-46be-9e62-f6764f0b8249	07:46:32	17:42:12	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
04a1bdbb-96f9-4550-b015-aaf8f42834d6	07:54:38	17:46:03	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
6fd9cfdc-e42f-44a0-9c10-a17c451e0e5d	08:16:25	17:34:45	LATE	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ac44b7f1-7433-42c7-b2a5-8f328daf618b	07:50:24	17:41:00	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
57e40a5f-b5bf-4575-b98a-20a4937dca0d	07:50:19	17:44:55	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
70b76d5c-af68-4323-889a-eea2ba5eb3bb	07:48:46	17:44:47	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
77bce83d-ddc6-47aa-90bb-0aa643b930e2	08:19:18	17:10:51	LATE_AND_EARLY	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
fb0a4e0f-3409-4fd5-a12c-80b654d76028	07:59:27	17:43:08	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
686cf7d6-8f63-4c63-b43f-3a27a7423488	07:54:05	17:34:13	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
8b817ed4-5261-4d8e-bf33-b24e1cc248ca	07:58:33	17:40:04	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
ae6eb33f-04d3-4063-84b4-5a428633e19d	08:23:48	17:42:05	LATE	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
703ad547-ac27-4663-af2d-755f9cc6633c	07:55:58	17:38:26	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
be6e924d-b5f4-49f7-abc2-1a2b0710c4ce	07:52:45	17:48:48	SUFFICIENT	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
163bc2d9-f707-4c21-a2d6-cf5861b16a81	08:11:11	17:42:18	LATE	2026-06-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
3f1cc365-7758-4969-a693-f0d069e3980d	07:45:52	17:39:53	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
61e8bad7-5018-4c91-91ae-945659e49655	07:52:35	17:44:14	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
d8c8be37-eeda-49e1-bb1c-4db8aa07cc45	07:45:09	17:38:19	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
e29a3eec-c275-4ccb-8214-9503d1859537	08:31:40	17:45:07	LATE	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b0fcf637-8cd1-4f92-b2a4-3ef097e93cbd	07:59:18	17:43:11	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
0633f8d7-2fa5-4f2b-9583-20ee6269943a	07:56:41	17:37:01	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f4e1c1a6-2980-48bb-b185-c31e8ebcb6d6	07:49:31	17:32:38	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
d4df3e19-8e3f-4999-bc92-8d92a8170a5e	07:54:30	17:48:27	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
fca9044b-9335-4a70-828e-b5f6550c02c7	07:55:43	17:45:44	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
afa2089b-3876-4e0e-8fc1-e662d0cfa058	07:50:32	17:48:01	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
1abdf6bf-7f50-4cd1-b8fe-cf6cdcdcd569	07:47:37	17:31:09	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
1d0ad250-9ff2-4c77-856a-51b54b67852a	07:59:44	17:34:22	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
578aa6aa-86ed-4e9c-b924-3f2774d60557	07:49:23	17:43:40	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
8cfa29ea-a529-44d7-8bc4-f908d3daf2b7	08:16:03	17:39:18	LATE	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
58eab100-53b7-4ee7-89d2-09056585cd53	07:59:04	17:46:12	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
25559c58-d337-4fce-b0a9-60c6a60d3dfe	07:47:48	17:33:38	SUFFICIENT	2026-06-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
8e66ee67-cd02-435c-815f-4545880b7bd4	07:53:20	17:40:52	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
06fd37cf-18be-4d98-a159-24f5672ba4c8	07:57:19	17:38:43	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
c161549f-f5f3-41d2-a438-d3b7c2a6e146	07:50:06	17:47:37	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
7e2ffe2b-077b-4e07-9a00-9b75b78cb76f	07:47:00	17:34:33	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
339fb37d-043b-46ff-bb04-086c2c35adea	07:57:31	17:43:21	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
fe654a23-c5e1-44fb-a708-7237439e7899	08:10:06	17:36:09	LATE	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
dc33b364-62e9-4a8f-a5f3-2d99a5c10db1	07:58:12	17:47:39	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
9e87f04d-610e-4ee3-ac04-e618fcd6dd80	07:53:54	17:47:45	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f469f682-358b-4f0d-a72a-35436d5d9448	07:57:51	17:33:26	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
03c72b4a-b97a-4700-a3f0-ad6a27c92c41	07:46:07	17:34:59	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
7acad0b4-8199-4edd-84c5-1b0973f7c3d7	07:50:19	17:41:08	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
3b754e4e-b77e-42ce-9da5-547041e8405f	07:59:38	17:46:48	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
95e443fc-5370-4ff5-9cdd-65172bb2a4a3	07:50:45	17:09:01	EARLY	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
dfb32b2d-16ad-491b-92d2-08c6fbd08e66	07:46:14	17:34:54	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a7790895-2786-437b-b7f9-0dc3cb29c8a1	07:56:14	17:39:08	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
1fdb697a-178a-4ba2-9512-67adbb7751cc	07:46:27	17:33:04	SUFFICIENT	2026-06-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
702f0041-9c54-4404-a3cf-6d622a388533	07:52:48	17:43:02	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b0ed7956-870c-45e2-a5d6-a2f020c647f6	07:45:50	17:46:37	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
4cd8ac3e-cb82-40ad-951c-9f1f67634877	07:46:58	17:38:02	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a8d7def0-2b5b-40a0-a442-fa34edb0bd4e	07:55:00	17:33:50	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
d66947b5-c3f9-4b5b-9965-efded8843475	07:54:13	17:48:57	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
3585ef56-d2ad-4359-ada8-fe2a361a6970	07:55:22	17:30:05	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a39014ef-c3bb-42c1-9fde-8dfb41c9a766	07:56:17	17:48:22	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
75de8090-7275-4ce5-b8d7-b0279fdae906	07:58:32	17:49:15	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
6200e090-d530-4593-8476-3315e4a0f7d9	07:46:06	17:48:48	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
25141452-c0b7-41e9-ab66-f6377ff1b7de	07:48:45	17:36:18	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
fba04177-c64b-4690-bc20-7dae3d5884fd	07:57:34	17:30:46	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
60cd5657-769c-4b56-bc53-1f83a7041250	07:48:58	17:46:54	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
e3303781-fccf-4a11-b402-50c5b08160c1	07:50:44	17:48:11	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
05da7341-fa26-4e2a-9fdd-de49b4da8da6	07:46:11	17:41:24	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e3d17eb1-7af4-4eec-9952-8451583713d0	07:53:14	17:43:07	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
736f2b26-ec68-4204-96ce-899bbe42c1bf	07:50:07	17:44:07	SUFFICIENT	2026-06-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
b1f1e523-d71e-4f19-9ee1-b0241edb0e22	07:52:48	17:41:45	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c00356dd-98d1-4fa2-b6fe-e42d2d02a4a1	07:56:02	17:32:20	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
94edc652-2b7d-4b60-9a6a-ad1c58b87716	07:51:18	17:44:38	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
947eb2a2-8e21-41fd-aa58-1bb5c66d2eee	07:55:53	17:44:14	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5683093a-b7f1-4756-a162-b8cab21e0cd7	07:49:54	17:43:12	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c4d517f4-785b-4d53-89a0-88e4ae3b77a3	07:59:53	17:45:43	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
c3d21bfd-721a-4ed1-bcbe-f1bb5176477b	07:45:43	17:45:43	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
031b7839-d257-4598-8869-42d5b9f783e1	07:52:33	17:32:07	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
34e6420b-14ef-4c4c-b2a2-b4cc54840753	07:51:44	17:48:06	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
bc9ef0b4-619d-4d20-aeee-269c7ca40179	07:59:10	17:32:23	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d30d7b5a-87c3-4ac8-a6e4-b253081fa00e	07:53:12	17:12:07	EARLY	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
798ac737-82c5-4f56-a2a5-b76abf9b8ced	07:51:46	17:45:17	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
38f167b4-ea60-488c-b9ed-d9e668c4d58e	07:57:37	17:48:17	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
495b561b-c4c3-42e6-acab-8f9fa33ee786	07:57:41	17:42:22	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
1466ac7b-0fda-4d47-973b-eda98b8b7e6e	07:54:25	17:45:32	SUFFICIENT	2026-06-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c3d3cb56-f2bb-454c-81a3-5d3d3d834332	07:57:29	17:33:07	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
243fb830-dc25-4a95-b6d6-3570c0af233d	07:52:14	17:50:08	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b998fbbd-d1ef-4208-b432-ee41e7752a8c	07:56:03	17:32:31	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
1fe86bbc-9188-43b3-9aed-1473066d71a5	07:47:24	17:49:43	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
41fd4e38-849a-4814-9ca7-b16ed02ebdee	07:49:39	17:49:06	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
bb05b405-1b5e-446c-97b0-fc63ae95a387	07:55:48	17:46:49	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
707fe534-865a-4fe3-8721-90729abf5bd5	07:52:12	17:39:42	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
16cb2ff0-0a3f-4ad8-ac6a-90688d60e6ce	07:53:16	17:47:21	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
e95151ce-7108-45b2-8b4a-5f6858f369cd	07:53:34	17:30:48	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
5f90e1d2-b965-4f3f-b760-41f4275e2648	07:51:56	17:33:24	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
0182f778-6167-4fde-b009-9b0213692ecc	07:58:24	17:44:29	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
7f8f3d83-4fd6-43d5-a569-9e9af55f5c17	07:47:35	17:39:56	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d9d4f5db-8ac3-406b-9913-c6ab740d91d9	07:52:27	17:34:19	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
18348293-0dd8-4f38-b161-d22f951d97d8	07:52:48	17:33:36	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
24d29b36-8c3e-4ba5-b962-827ffbf700ab	07:55:35	17:47:36	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
af8f849b-a409-45be-ac2d-dac38ce9f14c	07:53:54	17:35:32	SUFFICIENT	2026-06-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
49ec1e73-f112-409b-8064-89688a5ad4ff	07:49:31	17:48:24	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
0a7208ca-0d5b-4c08-85f6-4e7c9ec51bcc	07:50:49	17:39:20	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
e2b98caf-b339-44bd-8349-615705275182	07:54:02	17:34:53	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
9a5a4371-32fc-4add-904b-960147fe39da	07:57:47	17:48:01	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
1642dadc-c0d9-41d7-9107-e5d0fbeb1927	07:55:21	17:42:06	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
29f1116e-fb6c-419d-872d-3ec9bc65509d	07:50:26	17:41:03	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f7a82eb3-3d61-4ef2-a384-ed65da2d6a9e	07:48:15	17:50:19	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
5a25cfe1-50ea-498b-af1e-576430378fea	07:59:44	17:32:55	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
c9854d91-bbb0-4550-b906-64396ac90b4b	07:50:10	17:30:34	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
308bf746-76d4-4e28-b0be-7639855581bc	07:52:42	17:43:36	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
05bdd30c-de39-4670-ba1f-5e00d9cb1af8	07:51:17	17:30:44	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
e162e719-c90c-431f-8748-e9461cba2440	07:45:20	17:42:36	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
73785b39-84c7-4fb6-b06f-ef405c9f495e	07:54:06	17:45:06	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
5257d060-bcad-4954-b259-41e3e08f6f54	07:48:21	17:45:32	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a8419b7f-00c4-443f-900f-20c47c47a05b	07:55:21	17:35:39	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
dd411ea2-dfea-448a-8592-1f8c85d51a90	07:51:12	17:45:40	SUFFICIENT	2026-06-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f0a25360-558a-4162-ace9-f865bb64507b	07:57:04	17:47:13	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
44f02713-5afe-41f2-aeef-485e661b6a6f	07:45:19	17:48:25	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
7a7797ab-8b26-4f88-9d96-707992942d89	07:54:47	17:32:45	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
73b75276-d388-41c1-b2e9-5364b46deb45	07:46:37	17:40:17	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
c80ee50e-191b-493a-a7cc-d2cf3d7cbe37	07:57:33	17:45:27	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
579ff73d-ebf9-4bf7-9927-4ceba5a6852f	07:57:04	17:50:52	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
115b27a7-d97c-4f36-a1dd-9b9fd3777d56	07:57:19	17:43:42	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
05a73284-2281-4cf5-babc-2adee31ea83b	07:48:26	17:42:16	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
323809e2-5abb-49f2-bb2a-40134ba370a6	07:52:42	17:47:11	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c380a40b-2217-454c-b1ce-f3969377c948	07:55:45	17:46:55	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c60dc545-10ac-479c-a2bb-f7f11f80f990	07:52:13	17:44:17	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
439f3af1-ef5f-4882-b475-ad2b15b4608f	08:22:51	17:43:59	LATE	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
703cf4f0-229c-4ec6-ac90-53dc032fbf37	07:55:03	17:46:12	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
637fa6d6-6940-4be0-8c5c-bab7186f05b1	07:47:15	17:34:47	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
f090d2c7-45d6-4aca-a32f-1e30998e2431	07:49:54	17:43:26	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
c2056450-322e-4f55-8b5b-340a94ff750b	07:58:58	17:32:40	SUFFICIENT	2026-06-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
43c92dff-3967-44ca-9cf6-886253e79005	07:51:17	17:39:41	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d1e62bc9-49c2-49a0-9d0b-5cd4b67815b6	07:55:38	17:37:25	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
d5d42869-37e8-451b-9f9e-0fc4fd928273	07:47:12	17:30:15	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
17c9a302-1260-4e41-8a99-3b4066f77cdb	07:49:29	17:45:35	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
efeb91fd-a67c-4ef0-8a77-f19ab94050ab	08:18:41	17:06:12	LATE_AND_EARLY	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
97f9b15f-2e43-49d2-947d-55a68b8fbefa	07:47:01	17:38:50	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
82449e02-db86-4983-97cf-0bf8f6a2d19c	07:55:35	17:35:41	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ff318019-91c0-498b-aa1c-1d0eec3eb34b	07:56:31	17:30:03	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ce074cdc-741c-4d7d-ac48-8f5ed8186ffe	07:46:20	17:49:19	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b17b11e9-0f2f-477d-a94d-83f8f1d4a263	07:59:26	17:41:42	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c251efee-3e3d-4aef-8173-4618beea878f	07:46:25	17:34:15	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
43f1dda3-04f3-4d78-a59f-c04e01926493	07:56:32	17:33:33	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
59364295-58a7-425f-84bb-f89e09c7e807	07:54:49	17:46:16	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
9a861466-1a02-4baa-8c3c-0859de5222ae	07:46:15	17:49:07	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
4f8f7434-d081-46d3-be01-c0daf0d439ce	07:50:21	17:48:47	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
5e332dde-3ba0-4907-8e71-f372ff68b23d	07:56:47	17:37:59	SUFFICIENT	2026-06-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
0ea4b74d-18f8-4ece-9d03-880fac277bb8	07:47:06	17:35:13	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
32b4c225-7906-4196-9951-48f7b0536b66	07:55:26	17:08:55	EARLY	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
bea42306-2d73-4642-8685-4c7d5eab99de	07:52:34	17:41:44	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0fe3d903-91e9-403e-8efe-74ccacf19d02	08:15:34	17:43:30	LATE	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c27ad073-798e-4f67-a649-966a19190bd9	07:49:56	17:34:23	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
155fb871-46ef-4373-9f52-c8b5e1602c13	07:50:52	17:39:01	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
941cfb82-2c0a-4932-b9ca-e9e42c15a314	07:59:38	17:31:53	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
83f959af-57f5-4af3-b49a-43bc79059396	07:57:03	17:37:16	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
bbe06a10-07d6-4379-a03b-73910e6450ee	07:49:40	17:41:57	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
f7038ade-6c9d-46ec-b296-8e11642421f6	07:46:34	17:37:54	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2c536b5f-8445-4f15-90a9-2528748bf83e	07:45:58	17:42:59	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
806f6fd6-a5d2-4ca7-8ff4-0ad46a5a3135	07:52:19	17:02:59	EARLY	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e69d141b-3afe-4255-b4ee-c26d6784ca76	07:48:19	17:36:55	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
734cc3b4-e790-411d-8d6b-84d3afa16cad	07:59:28	17:50:20	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
d77b4e60-7139-40b0-82d3-4f89b1ef5e9d	07:57:41	17:43:50	SUFFICIENT	2026-06-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
0e2feeaa-237d-4e49-b51a-8de4169e9131	07:58:05	17:45:30	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b6206289-6e47-4822-a90b-d474ada77687	07:59:53	17:40:45	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
37361698-eaef-446f-a6c2-0b50d71bed1e	07:59:52	17:33:52	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
317f75ab-8dd8-4842-9606-42dbb0af5182	07:49:32	17:32:22	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4cee8feb-58f5-4dd4-9af5-a7f44c128a8e	07:56:52	17:47:47	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
2cb11162-33f7-4f68-84c0-7943095f871e	07:56:01	17:31:41	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
314b9e5a-d48e-4328-a091-2e1a8046b7f0	07:55:28	17:50:08	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f3e8476b-85b3-4923-a6f0-ce299b101f1d	07:48:40	17:39:20	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6ec606c7-2950-4d3e-aaaf-f52aa7b4ec64	07:46:10	17:37:33	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
25e30ee9-805e-414b-96b7-130d311472b1	07:57:53	17:50:48	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
64161471-9020-4b59-a43e-eefb22050b3a	07:54:43	17:43:50	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
0b472757-bdd3-4a18-b479-208721ecea85	08:19:30	17:34:16	LATE	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
c49e74ba-552e-4f09-be21-09487bd44132	07:54:52	17:40:51	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
51334f31-ea0b-4af9-ab8a-1b68614482df	07:46:26	17:41:11	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
883c2b5e-4763-4f05-b3e8-f43fe72f29df	07:51:53	17:48:14	SUFFICIENT	2026-06-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
198fdfe2-2d42-4871-9d95-7d7206c82c00	07:45:59	17:47:41	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
cb3cab97-5cab-4f06-83d5-16f90c5063ce	07:48:58	17:32:29	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
c88fb2b7-2de2-42bf-a3fb-2695cd5dcc7f	07:56:54	17:35:03	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
1726b8fe-dc2c-4661-aee1-e026503b15ed	07:51:38	17:38:09	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5571c507-810c-4999-9f1d-e64531c43195	07:50:10	17:48:07	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ff14a67e-8a97-49cb-8125-859eaeaac550	07:53:27	17:44:52	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
8c58474d-eae7-4f9d-94fe-8a9f45cd900e	07:46:14	17:36:12	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
4acc486b-e6d9-4f99-a0c0-8a78c5a3385c	08:31:50	17:38:18	LATE	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
13a763a3-2b42-4418-b8fd-d95f09628fc0	07:51:08	17:43:54	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
837a070f-481c-463e-b1af-e95783ac32ac	07:48:52	17:39:46	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2b5603f0-78f4-4c8e-af42-46fc447eea1f	07:51:11	17:43:50	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
70d0e9c4-2868-4b1f-965c-11b65cb7b521	07:49:16	17:37:39	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3c3a9a92-03ea-4fde-97ac-0758ffc6abe2	07:48:23	17:48:43	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
689d5a88-c583-4f5d-886e-a47e89e4cd99	07:46:00	17:45:08	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
2bc6d0c0-5aaf-4d5b-a621-373384f24bb6	07:56:25	17:36:45	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
00f998d6-5b35-4f4d-b5fe-2aec4d0341be	07:51:47	17:49:16	SUFFICIENT	2026-06-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
05f99494-9c25-494d-b0a6-0a4626108e34	07:53:03	17:31:21	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a4fbd19d-f283-4339-affe-ec455e152c3c	08:20:58	17:41:38	LATE	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
76b3797c-2d0f-4428-ae38-689a1cee0d22	08:35:51	17:31:00	LATE	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
720eba17-df06-4966-baa2-f93c8f483d32	07:54:24	17:39:25	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
aa9db00b-4f04-4f67-99ba-04f4cf9a8b6a	07:47:57	17:47:02	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
0d581045-a98c-456f-b8db-4bebac761719	07:49:10	17:46:31	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
25a60677-9a2b-4869-9f64-45d72298ea26	08:33:29	17:34:05	LATE	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
6287ca1a-1360-4473-91a5-5596391a1016	07:53:27	17:34:16	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
2d3010f8-dcdc-4b73-aab0-c5d3e075bbf9	07:45:08	17:45:55	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
0aeadec8-bd81-489c-bb90-c6592b258c7a	07:52:47	17:11:59	EARLY	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
1f0c7e88-bdaa-46d9-a783-97ddd6f8321c	07:59:56	17:38:39	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
abea811e-c203-41b8-b2ad-9fe5eb53eafd	07:59:16	17:46:20	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b797b7cd-3986-4f24-9f0c-5ce9d0039f02	07:47:20	17:45:48	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
107f46d5-6eae-4dbe-8328-f24d697b82e9	08:22:54	17:44:03	LATE	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
bdcd5a8c-3000-4da3-8c8f-7951a0fb6362	07:45:14	17:35:02	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
aa7103f8-016e-4071-878f-a2f9e0a5dbf5	07:47:45	17:44:27	SUFFICIENT	2026-06-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
74f9e9e8-109e-49d4-9b67-1f7909ed6e28	07:59:59	17:45:02	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b9fe0bc5-186c-4203-b701-ba31d78a0822	07:56:35	17:45:29	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
1ac47320-3712-4945-aff9-765d28b6af9c	07:58:46	17:34:07	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
4613f006-de5c-4b38-8e91-a1ea884ff3be	07:48:55	17:39:11	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
1d32e7c1-b0ba-4e7b-9457-154c74817f83	07:56:32	17:38:36	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
aa6ee24e-c599-40d4-b350-0125d8c2ebe0	07:54:13	17:48:00	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
7334517d-7c6e-4dd2-9621-1960ccd60a36	07:54:11	17:43:58	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
4317271d-acf2-4e0b-8d7d-ed1be3569b48	07:57:31	17:33:56	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
c2d1d4d1-2596-404d-bc2b-d732f8197bd8	07:49:43	17:33:25	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9038c2ed-2e20-419c-af43-2d9ec3f98653	07:59:06	17:40:09	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
3a0a8196-4d37-481b-8491-50bd3f0f9dc7	07:52:53	17:45:29	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
13e1b2cc-d1fd-4fd8-a642-62e335d8afe1	07:49:38	17:30:21	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
e7a45139-562f-4e69-8850-e4f836008edf	07:58:39	17:14:20	EARLY	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
219c4718-7d0b-4c58-ae58-ddd5553bde17	08:28:58	17:34:13	LATE	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
9c3efff9-b68b-485a-a3ba-04a861b44f29	07:57:41	17:39:20	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
353593de-a425-4e66-af48-1159e54a698a	07:56:04	17:47:38	SUFFICIENT	2026-06-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
7565614e-48e1-44a8-998d-d74323e98347	07:51:16	17:35:15	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
31093537-b36e-4ae9-87f1-7ea5eed758fb	07:54:05	17:00:54	EARLY	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
951384af-1063-4bbf-b3fa-f6619e5464b9	07:51:49	17:42:18	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
fa811e1b-3eb5-4e84-9a01-54445a5b00bb	07:55:09	17:33:19	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
c3bb0bb8-1f8b-4114-866e-9a977dced15e	07:51:47	17:39:57	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
45e64dd6-2ab2-4245-a588-b1aac7635669	07:47:22	17:33:53	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
39df429e-dd93-4c63-ad79-d5afae44df9c	07:48:31	17:44:56	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
12bdfc6c-8a81-4eb3-b7ae-81ca754e06a0	07:49:36	17:49:27	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
968e7900-7e4f-4b60-9f47-db27dea65958	07:51:51	17:41:39	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b675b3cb-3a79-4411-b997-8c09281e42e4	07:55:27	17:32:02	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
5aea009d-de7e-4910-9f02-3db02a6bed8d	07:52:43	17:37:41	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
50fe8194-3851-45a8-9a90-ff8768d6e79c	07:47:59	17:45:33	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
275d5db3-0e3b-407c-96a2-504b8a8b329b	07:53:05	17:39:29	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
55878e27-003c-4011-83a9-a01d4997687f	07:59:51	17:45:19	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
7e0a6d06-9d5f-4b40-aca0-470b897e30b1	07:47:43	17:39:53	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
2023da6a-bee9-46a0-8396-f510c46c5b46	07:51:18	17:48:03	SUFFICIENT	2026-06-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
74590a62-1b6e-4464-a5c9-db0c3b92538a	07:59:02	17:46:06	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
599ad399-0bc5-47d8-9766-f63ba7c98808	07:51:06	17:44:42	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
e035bf45-3534-4545-8b3b-eda5580240e7	07:58:16	17:41:16	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
5d65a6d2-064e-4971-a281-0a4510a5e525	07:57:32	17:30:07	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
16d21d08-3f20-4b9c-8eac-1786c6d22a02	07:52:11	17:35:53	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
94069130-01fc-449e-b6a4-6fba233e037d	07:46:26	17:39:20	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
181d56a8-6027-46a0-bdef-210be76a7afe	07:52:48	17:44:39	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
1bdcb0d4-8368-4c48-acda-67ff678bff2c	07:50:58	17:35:13	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
61c35338-c4fb-4601-8e06-2e60b87cb228	07:56:38	17:38:55	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
44b23f87-082f-4139-9b26-7aceae464b6c	07:51:34	17:30:00	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
8e73d15d-ea5f-49ec-8d14-7476c7f9aa54	07:45:10	17:50:30	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
e25cffdc-4c80-4e26-96b0-2812262e9896	07:51:55	17:49:46	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a438d3b0-5bb4-4d44-b320-bacb61738b0f	07:54:52	17:49:23	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
77b5074f-e70c-4f8f-b29d-566b25a52b71	07:56:43	17:42:51	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
f1dac8c1-6f39-4853-ab14-49704f50be84	07:47:08	17:30:12	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
4b691e71-4220-4142-b8ba-daeeca86b748	07:45:44	17:36:54	SUFFICIENT	2026-06-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
128044b4-21b0-485f-add0-f58a94bae0d7	07:52:41	17:34:41	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d7d7384e-5bb7-4500-9d3c-03c0f1d82047	07:58:40	17:47:12	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
7e774c49-3706-4cfe-889d-8bab951f9728	07:57:29	17:34:30	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
93bf2998-a80b-4769-a8b9-cbf80d3c9b2b	07:46:10	17:34:47	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
ac115f36-0531-4b94-8524-5f695b118506	07:52:30	17:30:55	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
187943d0-0814-43c4-94da-4dd34db64164	07:48:12	17:39:36	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b15a8962-fc48-4f92-ae89-e70466282a45	07:51:03	17:40:00	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
e694ea0b-2442-4f76-9165-b94de0603b74	07:58:45	17:43:26	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
41180edb-d62c-479c-b3df-c208611759bf	07:56:37	17:49:46	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
d40e917c-76f8-4978-86b6-0cec100c3e2c	07:49:02	17:45:25	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
b7e93693-b40e-4e36-aee9-d2116c553641	07:54:46	17:49:59	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
e74dd380-8eca-47c3-bf7d-4c10e03b6cec	07:58:55	17:45:14	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
c729aa6a-b17c-4c82-a938-e9f110dbe505	07:53:01	17:43:36	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
20d742cd-f165-4b2f-af3f-092885ce8d49	07:46:17	17:50:26	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
df0eecd2-34bb-4336-be49-3f84f9ebcae9	07:46:31	17:49:41	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
876e8c78-2fd2-4e1a-a6d3-ff2dfa5968a6	07:56:27	17:30:10	SUFFICIENT	2026-06-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
7d31940e-ca42-4090-b54f-1ec865a87706	07:48:30	17:41:28	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
9ec8a524-82bf-4ddb-b336-b93e80de3843	07:48:37	17:40:58	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b75788c4-2f69-4be1-92ab-170a174e92eb	07:58:45	17:44:08	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0f5b2acf-397a-4097-b9e2-26a1820defe1	07:56:45	17:42:26	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
3b5460cd-0b71-4c23-81ec-757f3544ce0e	07:55:41	17:41:50	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d682cb70-eb7d-4653-be20-bc35b0202dfb	07:58:10	17:49:13	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
faee6f18-9386-4ffa-8565-4cfb718fba3b	07:56:05	17:45:08	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
9e8abc9f-af98-4ff2-b74e-21cd7f3d2734	07:47:38	17:45:06	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
4e0807dc-04df-449d-b327-053228cee2a1	07:52:19	17:37:13	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
314d2a39-df1c-4603-a6d3-70397e5bc3b4	07:45:22	17:38:22	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
4bac5552-0bec-4edd-8f4c-44957e3bed59	07:47:52	17:46:02	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
c024f208-f9f5-4d45-87cc-ca3cd299c0ed	07:50:27	17:33:39	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
cdc8407b-dfc4-49c0-b1f9-7a3cc3f763a3	07:53:14	17:45:16	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
83b06689-5223-4e93-aae4-8ace15a8d984	08:16:49	17:06:49	LATE_AND_EARLY	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
166bcce4-ba43-413c-837e-7107d0e3be10	07:49:57	17:34:54	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3bff5e33-1930-42a9-b4f8-4fd56946e61c	07:53:38	17:33:45	SUFFICIENT	2026-06-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f87b5306-c050-4fa2-9d88-aeceba002bd6	07:52:51	17:44:53	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c1067901-1735-4eb3-b7bc-1972925664cc	07:46:50	17:49:39	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
dd28d7dc-0507-4c67-a4fb-ef7f5ccdd3ab	07:46:52	17:47:02	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a10419af-a1d5-4c04-8120-fac895c91bb5	07:47:40	17:33:55	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
f510cbd8-661d-43dd-8339-ce4719e6507b	07:50:10	17:39:45	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
8c675df8-6c1e-454d-94b9-933a20c3a8c2	07:53:31	17:33:09	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a1a0019f-5db6-4387-a36b-5f0722652b2d	07:50:52	17:34:07	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
957b8bca-15d8-4793-9842-ec124948187e	07:52:26	17:30:15	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
2263d478-ca31-4906-967e-12ad546946b6	07:52:21	17:39:32	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
3e984984-e4a7-41ae-8cc1-9c6b578695a5	07:49:23	17:43:23	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
efa6bafe-7f94-46b2-bf1b-5680c628d7eb	07:48:09	17:46:26	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
63ca96d9-4a53-449e-bb15-073f8a3ad26d	07:47:51	17:43:26	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3a1e4f32-8cad-4575-924c-d80cc822dd1c	08:33:29	17:41:01	LATE	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
0c70d5cd-1dd9-4c6d-9db2-2d88b71c328b	07:57:00	17:46:04	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
f3979c88-e46d-4872-9bc3-61097121a4b7	07:50:25	17:35:27	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
6b1da892-8854-4b24-b408-4cda54518e8c	07:57:02	17:50:09	SUFFICIENT	2026-06-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
311670cc-cd7b-41ea-8408-59cf86e8754b	08:06:40	17:39:26	LATE	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
72e4d228-3d6d-4545-9912-a213907a481b	07:55:44	17:47:55	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
d64188e2-59fd-4991-96e0-bde309b453f2	07:56:20	17:41:00	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0ffc97ee-a254-4fa0-8169-ef0b64d43546	07:59:33	17:49:58	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5091128f-c1b2-428d-8304-ef7235dfd309	07:51:28	17:50:13	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
66a0a2bb-dee8-4d45-a176-165393a5209d	07:54:50	17:49:41	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
4eb1a3f3-06ec-4b5a-bd32-e098bbf51356	07:50:56	17:50:25	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
69d94e9c-6ab8-44bb-b766-7288ef79d973	07:59:19	17:32:02	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
298196b7-8ca1-40a7-ab0b-fb04697c75a2	07:51:46	17:34:33	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
8e616140-d1e0-4f19-90ab-80a1062f6546	08:14:13	17:07:32	LATE_AND_EARLY	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
85ec7d7d-9c6c-4384-9a4b-5c501734120a	07:53:21	17:50:10	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
fac58f96-2b48-42bd-a6dd-615a2dea9540	07:59:50	17:47:37	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3c54a789-1dd3-4627-bfc2-9f4035eb4388	07:58:49	17:39:46	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e584c231-cd3a-4eac-962c-f52615967f80	07:53:07	17:31:53	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
7d6c238b-a5a2-4664-8673-794ad97a62a5	07:55:32	17:41:07	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
9de3cf1d-65d6-4076-8819-b1e3c05330f6	07:55:07	17:44:19	SUFFICIENT	2026-06-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
7d0a9e29-0564-4f2d-8dae-dced7e8543a9	07:45:29	17:40:15	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
4db62caa-d3ba-46c2-a00d-9b009a32c08b	07:54:36	17:50:42	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
8e46a650-ae56-4e51-9094-c6c0401fde3c	07:54:14	17:41:19	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
75839a05-ee62-4c14-9f02-7172f96697e3	07:57:52	17:48:43	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b517e5fc-c82c-45f6-9d9b-3514eb0fd562	07:51:33	17:37:06	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
8cff37f8-e9dd-444b-b980-858d3bac57cf	07:54:12	17:41:29	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
5416a8aa-0b9c-47e3-bd68-670b84051972	07:56:27	17:43:05	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
dad2481f-3035-4288-87e7-5182ca509a25	07:51:56	17:34:30	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
7e50592e-4ab7-4da5-94d2-489e2fb34369	07:46:23	17:46:25	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
0005509d-0977-486c-9a34-0c2335334dd6	07:53:49	17:42:55	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
23d62533-17b8-4b5f-bb11-35e4c1cf52e2	07:52:40	17:43:28	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
d37bbf2c-98e7-42e6-9a8e-9d6f38917e34	07:52:46	17:43:52	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
4d35d4dc-1eb0-4cf2-a8a7-4dd08ce788d4	07:53:08	17:45:45	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1600afd9-e159-4b54-b300-7aa403347f95	07:56:32	17:46:07	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e70e8279-67c7-47eb-ab7c-1ccb23968dd6	07:52:30	17:31:47	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
8482f6ec-3326-479e-ab17-78484d99f46b	07:53:23	17:33:38	SUFFICIENT	2026-06-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
56741795-019a-4ccf-9fae-ffc6dc03f7a6	07:46:07	17:41:36	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
0b2c8225-4420-429e-96cb-4140669dc263	07:53:09	17:33:23	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
93caddbc-1c9d-42fc-b4de-8e6d57b3e72b	07:50:19	17:39:31	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0e74d201-1f2a-4f5c-8ae9-464f52f2ecd0	07:47:09	17:48:26	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
11408ed1-c00e-4910-9256-eac6525ff47b	07:59:19	17:39:13	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
babaa1b8-ef37-4e48-97f5-d23c88ce2e92	07:56:31	17:30:07	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
10af0d24-f392-4ee0-98aa-a0226e4098ba	07:46:55	17:31:26	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f8363561-272c-46d9-85c3-3a4e8f538d72	07:49:36	17:44:57	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
91d7c653-15fa-4309-b3ab-f992cbcdde8d	07:51:30	17:49:08	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c9453ff0-7951-41f0-b17d-6b50e36270fb	07:53:40	17:44:48	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
34c37c61-ddfd-46d0-a532-5ee6a64cc269	07:52:09	17:40:05	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f0fae6ff-ba89-4680-bd4b-780bc7804ec7	07:55:39	17:43:24	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
e45bd83d-5657-4418-a85f-8cfdd93bf797	07:51:21	17:47:02	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
151ba6f5-c4da-4ad5-905f-cd7107b74c2e	08:33:28	17:38:41	LATE	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
ff1848a5-2842-4561-bf11-7bcdc6f14397	07:47:45	17:30:36	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
b862539e-9e4c-4497-90e0-84e8542ee608	07:57:45	17:39:35	SUFFICIENT	2026-06-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
4e1a6aac-0084-4d93-91d8-ce8913c2935d	07:55:35	17:32:12	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
bdfea8a0-0a2a-4831-bbc3-4a28affefadf	08:22:36	17:31:36	LATE	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
c729555b-c9e9-4f5a-b77e-165fe33445aa	07:57:30	17:46:57	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
8068833f-9c9a-4f5a-a79e-d738b2ed29af	07:55:59	17:47:11	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
f351842a-c810-43f4-8f5d-859ee5b3a665	07:52:50	17:06:15	EARLY	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a8c24a6a-4bd9-4739-be9f-1d8e9ec2463b	07:58:56	17:48:28	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
99ca7a53-a2ef-4f66-883a-428003c43ce3	07:53:38	17:40:25	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
8937b370-7065-42cf-b738-7840f6cbd1b9	07:52:55	17:30:21	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
e1b41d0e-f85e-4f02-b8d8-c103105d5952	07:51:01	17:46:20	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
628f7ac7-aa27-4243-820c-4e29f601762b	07:46:07	17:33:34	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
bc41e5ec-b61d-4b4d-9a33-1d8dd80bbd99	07:47:11	17:38:49	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
43180db2-9f9f-4420-8042-3f9ee3a9bc2b	07:49:26	17:35:03	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
51875d2e-7d68-4d98-aea9-95ac6278b6a4	07:50:11	17:30:45	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
f93fd765-4c10-4b88-a5c3-61d4eb3bede2	07:51:06	17:40:09	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d3d54c7d-a4e0-4bfc-a3df-ebdee0878ad2	07:50:16	17:42:52	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3bc77ba5-07a3-4571-8a90-358151745bf8	07:45:12	17:37:48	SUFFICIENT	2026-07-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
59df8f05-2546-4ca2-9ebd-6b4fd05c0b4f	07:48:31	17:46:48	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
cb5dd575-3f5d-4a6f-a7dd-a721f2c20684	07:46:17	17:31:20	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
4c4f28f4-44b4-4349-9c06-d341f390627e	07:51:04	17:45:01	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
7f327308-85cd-488e-bc56-fbdfd7763fd7	07:48:58	17:30:17	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
0658d747-8af2-467e-9c0a-55663904354d	07:54:43	17:33:15	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f63f2b37-5de6-4228-8db5-3110e99c4615	07:55:50	17:34:19	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f20c30fb-9e37-48fc-8a11-4f67abca06e7	07:52:05	17:50:32	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ffb3f37e-265b-4c22-ab53-f4739036496b	07:47:23	17:47:10	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
d1ae8064-b036-418b-a739-c2541ec8ff47	07:53:27	17:47:28	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
2ae1902d-45da-4b96-82dd-757231c9fe3b	07:58:29	17:49:18	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d1849f2c-bc5e-4f8e-808a-0480924221de	07:47:00	17:31:59	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
7d27e7d9-f24a-4ac4-a4fc-88974290b831	08:13:38	17:38:53	LATE	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
ed4a93c5-77c4-47b2-95c2-294b38bbfa62	07:50:53	17:50:13	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1d3f2174-465a-4b54-b682-8d8ce93e13d3	07:53:18	17:31:10	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
46b8cd9b-b76f-4910-a315-25906982955b	07:54:04	17:39:05	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
bd62a515-f56e-415e-a0c1-7a7b5243093e	07:46:53	17:34:46	SUFFICIENT	2026-07-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f76ab82f-3885-4b5f-8263-a1988c8ec903	07:49:56	17:43:13	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
96005791-9e6a-4d1b-adfb-0ac07ce0fd0b	07:57:20	17:40:40	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
d0047868-40f4-4a7e-9599-b855ce545b85	07:57:45	17:44:17	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
726be8a4-4436-422d-a3ce-d7280b96ca02	07:50:21	17:36:29	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
dd7870bb-6ade-4257-8213-6ab91b24e436	08:15:01	17:34:41	LATE	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
23125b75-0e87-438e-9f63-557e90fd87a3	08:24:30	17:30:57	LATE	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
631a5623-e4c8-45bb-8c8d-7da4af83f114	07:47:26	17:47:57	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
3d22359c-c1f3-4d7b-b5ff-32afdd515be2	07:52:48	17:42:34	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ea92125a-92ad-4086-b8d3-9cd7f542e5c8	07:59:41	17:50:04	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
dca51a5a-2c14-4e39-ad0c-aa7b5e702352	07:59:53	17:44:43	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
94c9872e-a888-4d2d-92e4-514a855bde2f	07:58:24	17:49:22	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
dba47f4d-02e3-4d99-b2b8-78fbd8c33bc6	07:58:49	17:30:07	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
5fcb6759-06d3-45a6-b6d9-e0e6d2d33320	07:59:12	17:44:00	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
f2870fd7-ce2e-4f69-9970-5ac7d454d76d	07:45:48	17:38:43	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
7e924d6b-0104-4d1f-8318-ed26e49ea6be	08:16:12	17:32:52	LATE	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
982d23b6-63b4-4573-9acc-430073fe59d0	07:49:51	17:37:14	SUFFICIENT	2026-07-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
15696735-5c62-4fdd-891b-31d811061666	07:53:02	17:08:31	EARLY	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
75d2dab9-545c-4a3a-8195-86433e8f560d	08:27:38	17:36:00	LATE	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9e67f46b-4acc-4532-bf5d-7228fdb1440b	07:58:40	17:42:07	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
add32f86-a0c7-464f-a07e-9ba37554fc80	07:54:32	17:45:10	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
37c6d47f-3a2c-4b74-8d9f-1742b76bafd4	07:55:47	17:48:43	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
b67cadd3-0d5a-44a4-9d8a-a57a5b63d6d1	07:54:11	17:32:37	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
3dc43c70-61e8-47aa-afa3-110b3c875d21	07:46:08	17:38:59	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
9033b982-6afa-4588-891d-398a7883ecfe	07:48:56	17:46:46	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
6f286ca9-0ca5-4b45-865b-a401bfc88351	07:48:54	17:30:44	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
520733d4-4d27-4932-b54c-8e810d774daf	07:54:16	17:47:56	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ff6c04cb-b5f3-4534-a249-0c112b4c214d	07:51:41	17:50:03	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
66d7f8f0-9346-4068-a69a-1ca41e0baf7c	07:50:27	17:43:17	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
0d880fc1-8970-42e6-a358-bf3a74037413	07:53:29	17:45:23	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
2a527959-3955-49b1-aab2-7045d9368e96	07:45:56	17:37:03	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
bd94a6cf-29f2-433d-bfd8-3d3e2cff7162	07:51:34	17:44:20	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
d4237350-c76f-4ffb-8aa5-da5ea34f6fe7	07:48:21	17:32:56	SUFFICIENT	2026-07-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
5672090e-a3c0-44aa-a5c7-b3855c37f3e8	07:45:47	17:37:44	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a6a2c32d-88cf-4c8f-9a1f-249cee32fd60	07:46:58	17:37:12	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
44ad63ef-ee78-45d1-93f5-545c3cc3cf93	07:49:04	17:50:40	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
9942b2ae-7460-48ef-9a22-5bfab4006787	07:52:27	17:30:37	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
2dd56f05-0049-4333-bab7-d20f7864e5b0	07:59:21	17:38:15	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
5690eb11-9491-4dbc-9661-275458ee038c	07:48:21	17:31:52	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
d43f3ddb-c528-4c3e-9ed4-853a16448b1f	07:57:15	17:32:49	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
0dcf27b7-8e44-4af2-adc5-5569d7fb1f58	07:52:48	17:33:40	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
596f7df7-8590-4f8d-addd-5a55fc87305a	07:46:05	17:31:58	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
72c44edb-1d98-461c-b5ed-833aa45becf6	07:50:56	17:32:50	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
63f8fd5e-35ce-47db-9f48-39c0bb1cfa5a	07:59:51	17:44:03	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
3e674ef6-b23a-4eb6-a715-68a61277ee11	07:55:27	17:32:06	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
43123699-b335-48db-b336-ebb5ea05e2aa	07:53:03	17:39:54	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
77ad5e27-6fc0-49b2-8c2e-171e1728ee76	07:46:39	17:43:14	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
9ceb6eba-6354-40ab-9e7b-fde5abb3b21b	07:57:42	17:49:00	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
0e28f300-cc7c-4aab-afdd-ba8c178933dd	07:52:50	17:43:56	SUFFICIENT	2026-07-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
3d6ef019-6a21-45a6-a064-fae046e4cd9e	07:46:21	17:50:43	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
16b49e38-8b54-4416-b145-e8117dfd8c67	07:52:33	17:40:37	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
f84d219a-ee22-44bd-8d13-e11418e541cf	07:46:00	17:49:45	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d56c050f-68ad-4aff-9387-07a79f8db128	07:57:53	17:36:57	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
9419cc1d-9e01-4c25-a426-8b8ee03c63c8	07:55:32	17:38:22	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
5faff7b0-6605-4363-a85a-73bc4c2a333f	07:56:39	17:44:11	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
5e65d9fa-34a8-48e0-af76-293e18ca3e9a	07:57:02	17:31:08	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
d8d88b40-7e41-45cd-86ca-a9bb0b9a54f9	07:51:32	17:50:48	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f3dcedfe-7af4-49da-9d47-b08ff5248e8e	07:54:56	17:47:49	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
eb85ea87-ba6f-4809-a4ed-bfef9fb78dcd	07:52:19	17:49:21	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
fb466251-2184-4d26-9c8c-7c4ac18bc75c	07:45:33	17:48:42	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
5daf3c3f-8c7e-44ed-8437-42980e173e26	07:45:15	17:46:52	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
0c29d084-3960-4a18-a5e9-3b48914c9359	07:58:03	17:43:22	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
b20bd753-1eb7-4650-83de-56ad8d9bb63e	07:48:40	17:36:50	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
ecbff1bc-9f82-49ff-b8bf-c4a4f55aeba6	07:48:42	17:45:44	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
318e8d0c-46eb-4c78-be2a-a2b0afe5c931	07:52:38	17:40:54	SUFFICIENT	2026-07-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
ab1fb907-e4d4-4160-9833-d14aeabe5f6e	07:50:39	17:39:26	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
1ecb4859-f4e0-44da-9b1b-de8bc8e3278e	07:46:29	17:31:31	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
73cb9fa2-6704-4d6d-836b-b0218683dd5d	07:45:40	17:37:44	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
73d32883-a9c7-4a0d-98ed-0d4ebf7ac036	07:54:13	17:37:30	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a5eb5406-d384-45ea-a04d-2e5fb5531b18	07:58:21	17:42:13	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e2f6174a-83fc-4647-8ed6-13f656d34687	07:58:00	17:41:00	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
1e662183-66b0-4036-9e98-763e94b7f8f3	07:45:35	17:33:09	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a421845b-30be-4942-a94d-2e89fcf90349	07:48:40	17:48:58	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
bdf797ae-6959-4f63-839f-87336ba7f50e	07:45:01	17:36:12	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
cc6bb6fa-879c-4f99-ba31-b6a6cea51a36	07:48:56	17:38:46	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
069860aa-4519-463a-a64b-b6a752c2cf96	07:58:35	17:37:11	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
c307523e-2c4d-44c5-9d52-f36b6e0063ad	07:47:53	17:38:58	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
c7477ff9-71b5-4738-91f0-247c6c70ce49	07:58:43	17:34:24	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
8b0d88fb-8ea5-4d51-b5f3-68c7ec3946d3	07:59:07	17:40:59	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
826a0c1c-8e64-484f-bd4c-ae246f9a9b94	07:52:15	17:41:51	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
0bf460da-4ff0-4dad-88bc-4f5d591cd0ac	07:47:33	17:49:56	SUFFICIENT	2026-07-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
04f4c01f-0df3-48bb-8e6a-2ac1039aec58	07:56:04	17:33:09	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
f5a6a9c9-7db6-4fa7-94f8-582caf17b332	07:47:50	17:36:12	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
785e2e5f-c9d6-4c1f-a4ad-58e7bc1e54e7	07:56:23	17:40:38	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
8b76d38f-cd58-46cd-a74e-b00e0a1a3144	07:55:15	17:31:48	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4457f5d6-b889-42fb-a5d4-29469d249a33	07:48:54	17:47:18	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
822fc633-e22a-4e3d-860f-e30d97879f2b	07:50:15	17:31:40	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f0bd21c2-dfce-4c03-a9d5-ab10260f0bc1	07:58:08	17:46:37	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
e21f8c70-5cfc-4024-9cbb-51862882d332	07:48:46	17:32:50	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a947b519-4988-411a-89a8-4e6ca053cca5	07:55:39	17:32:10	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
12404be6-a774-445b-bb7c-45a31fc22913	07:57:56	17:50:48	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
6f263fc7-37d7-4725-9c1d-2577768cd13c	07:52:33	17:44:11	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a5bd8161-e0ca-4142-8cd2-80c489bcf428	07:50:33	17:45:45	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
91a28688-b988-478b-b781-1eec65f9580b	08:20:17	17:42:40	LATE	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
7b0e83ba-6f20-4a79-8e60-56d458b0b4a4	08:23:41	17:31:13	LATE	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
f994fbb0-df7f-49e4-995d-d1e6632e1d27	07:48:28	17:37:25	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
feafc6ec-0ca2-4440-ad9c-8faf9a8cebab	07:51:56	17:42:36	SUFFICIENT	2026-07-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
30093894-0728-4b0f-a4f2-e0e7f87f196b	07:58:23	17:38:35	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
0b8a2934-1a32-4172-aff6-e5648c375efb	07:57:05	17:39:28	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9cbf0ff9-7639-4a64-b2e9-efebf9cdd315	07:48:37	17:31:29	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
2bbda9c8-1a82-4582-a939-7282ff1af12f	07:50:27	17:44:29	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
3b70cbf6-3656-478f-9eee-6c59edf78322	07:50:51	17:45:20	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
daa1853b-906c-4ae7-a8b4-09703c5df127	07:45:11	17:44:14	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ba00f26a-aef0-400b-9bf8-62f389c8791f	07:46:22	17:32:18	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
5d09297e-7214-4ddb-842a-b9fcfc34b5b7	07:53:34	17:50:05	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
dffb2696-450c-4bbf-b295-6b37799366b4	07:59:14	17:33:07	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
f343c5df-f598-4c83-b92e-1f7f3c4c722e	07:45:34	17:36:21	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
990e1825-7d8d-470a-b7b1-157757d1a7f8	07:50:16	17:39:47	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b0405c62-414b-4521-9978-dcb469e6b409	07:55:54	17:38:12	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
233ec473-ad56-40c1-ace9-acd49e1f9d28	07:47:54	17:47:58	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
2e956f9c-cfa0-4ead-972a-0ba218404e54	07:57:19	17:39:52	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b3ef1bc5-d0f6-48f1-9c4f-850f93453e6b	07:51:25	17:48:48	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
28863036-e086-43db-a271-1ef6b5b653a1	07:52:41	17:46:48	SUFFICIENT	2026-07-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c2071519-a66a-422e-b305-6bc10558383f	08:32:25	17:37:14	LATE	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
181486f4-909f-4a16-8989-bf7b1281b9db	07:48:30	17:37:33	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
3c974d8c-8156-436d-8392-89d0f9f4d22e	07:53:48	17:44:46	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
3fe72561-0867-4433-97d8-f261cc210757	07:50:50	17:32:20	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
34eeb7c5-3d5e-42e8-b91a-63a4c9960c4f	07:51:49	17:43:13	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ff714c20-717e-4fc1-96b8-633630df9218	07:58:35	17:30:23	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
9a1f80b4-213d-4ff2-9fb0-10f5d731b6c3	07:58:08	17:39:47	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
7bcc88cb-09d5-4c4b-bcd7-8962276b1626	07:57:42	17:41:21	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
e86609dd-c508-4bb3-90a6-864ea88ae33b	07:51:43	17:42:48	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6adde11b-883b-4438-8cf6-af0f0cd14317	07:53:19	17:40:37	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ffb383f8-7f3a-4f37-af75-e19c78acf11a	07:57:02	17:34:09	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
ddc649cb-4fff-4d43-99d9-3af59071ed1c	07:53:36	17:12:24	EARLY	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
8e08e041-5973-4e12-9a83-bd85b0b8b51f	07:51:04	17:47:24	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
451b0925-bffa-4c14-a236-bfd0a69d0aa3	07:46:21	17:48:28	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a9bb1f6f-52f1-427d-8c4a-6ee1573e6e1a	07:49:05	17:35:06	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f50c20f7-ae9d-4527-817e-2cf6a2b04c8a	07:47:02	17:49:31	SUFFICIENT	2026-07-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
4afa8878-172f-40fa-8a05-cfd9ae83231d	07:48:04	17:42:18	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
87eae402-425b-4631-9c99-9aa94f7f28f5	07:49:42	17:46:04	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
f02adfcb-cd8a-4409-8ba5-bd653e108e8a	07:50:33	17:30:10	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
bb952e9d-474c-4233-a79b-18a170b9674c	07:59:26	17:42:10	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
14aec46c-3e06-4758-bc8d-591165952e48	07:50:34	17:13:30	EARLY	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a462b312-ee79-4ee5-a187-23314be6ebf3	07:51:57	17:36:08	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
323446e8-914f-47ce-b022-48573e86ddbd	07:49:27	17:45:10	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f267a75b-288b-40e8-9076-18c801898999	07:49:37	17:36:32	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ca449ec1-0714-42be-9100-abc99038ad51	07:52:17	17:36:00	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9d7561e4-661c-47d4-9654-9d309b600307	08:19:04	17:17:38	LATE_AND_EARLY	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c511afe4-9f1d-462b-8189-0b9282712b1f	07:53:21	17:48:56	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
affc4adc-40ac-4b70-9802-1764c9f5f0fc	07:52:36	17:31:47	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
808f1099-b826-4035-bed1-5c7991f73b99	07:55:56	17:44:22	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
44e7ef4e-d3b3-4f37-b25b-4cedf6af34d2	07:56:50	17:39:25	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
7c0ec485-c924-4e39-b99c-f75a5a1c38e9	07:57:54	17:35:26	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f2dbc45a-28ed-4bd3-9e29-45876e5f4ac9	07:59:39	17:43:29	SUFFICIENT	2026-07-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
39dceef6-bc1d-4c4b-b2e9-915057cb1fbb	07:55:11	17:48:06	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
10f0e8f4-c89d-4ee5-90e9-4eb292589fd9	07:45:15	17:35:17	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
cdd7fa86-389d-4084-8040-3506fb7701c3	07:53:18	17:32:44	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
3d831233-cf1a-4d69-bdc7-969392b25d83	07:59:13	17:45:26	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
c1b9e127-3904-4b5d-81e0-324a14ba136b	08:08:23	17:07:48	LATE_AND_EARLY	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a24ca900-d0e5-4370-b352-79609bdfce69	07:57:49	17:40:26	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
519196bb-2a35-4cbd-b4c6-e217f99612b6	07:49:13	17:46:02	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
79273c1f-ad99-466b-8f07-4d64a8dd5e69	07:46:40	17:44:24	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
1fe6d4a3-63ca-43de-ad70-02a650d99f9d	07:51:54	17:36:25	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
0d6b3770-a1af-4ffd-a79d-478c9187b2ff	07:49:07	17:34:20	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
36f808b5-239d-418e-a14a-c6c2e1bb4508	07:52:31	17:44:04	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b1f84c76-36de-4938-85e0-7612123ab65d	07:55:15	17:44:08	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
7671afbf-48e8-4902-87d9-e1178898d74d	07:49:53	17:35:10	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
fb375983-66e6-44a4-b9b1-ae97cf41bc90	07:54:06	17:35:18	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b777e004-4908-48f8-8bfe-fd4df66adde2	07:56:25	17:35:04	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a9a83217-791f-4136-8d7e-ce8140936587	07:45:43	17:38:09	SUFFICIENT	2026-07-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
dc6fd285-4975-4ce4-be9f-5af0ae032049	07:47:13	17:31:57	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
85cd07e3-9b0e-4ce9-a3d0-b17f13f804ce	07:48:28	17:31:53	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9d3270ee-d115-4ee6-b6cc-b736be28e52e	07:53:41	17:33:24	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
c4b00ff9-1872-4cb6-81c7-6097e859fffc	07:52:03	17:49:00	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
9f5f5d28-c081-4e5b-acae-6364605e34d5	07:51:49	17:36:59	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c6dd42ac-31d7-428f-9149-90fba05436f0	07:59:15	17:36:05	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
4692dc6b-af30-461b-81ae-25ab6f1c8fe1	07:45:00	17:40:52	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
1637d3db-ee80-4659-be23-ba116260b6b6	07:55:04	17:37:56	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
41403c7b-b5f0-4ad3-ba98-0a5d88b920a6	07:58:53	17:35:46	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
0f2f99cc-db1e-45f9-acb7-6ac6fc22aa3b	07:51:32	17:33:52	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
4c1a8ff1-8f8d-42dd-8051-b0214f940972	07:53:40	17:36:39	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
4dbd2e69-ad6e-4f28-b9bf-bcb0943d19cb	07:53:25	17:43:07	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
107c264f-0be6-4450-a3a0-481a79b0e066	07:46:22	17:40:11	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
741748c6-5968-4f67-b263-11c4e1e1d880	07:55:20	17:30:24	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
46b4d483-41e4-4a79-96ac-dd26f0225bbd	07:48:04	17:38:41	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
7d467356-c347-43af-90ed-a971bf1a1c2c	07:45:04	17:36:26	SUFFICIENT	2026-07-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
4da246e1-566a-4bfe-82fb-8f715db8ed40	07:54:31	17:33:45	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
3484f276-6f61-448b-ae80-a805a51c01c1	07:59:54	17:48:10	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
e16cc96f-093b-4540-99a3-ec5b5f91d313	07:46:38	17:40:40	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
3b8d3904-0ec3-449e-bd25-45212f5b6633	07:55:59	17:34:21	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b8e85687-6966-4068-9c8b-bd209a9bc8e5	07:57:56	17:40:54	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
3f34f70f-c33d-4144-965f-419ef060cd42	07:46:21	17:30:38	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
71f88f6d-4432-456a-a1f0-2876e2ea4bb7	08:19:24	17:37:32	LATE	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
1fdeffd1-c472-41e1-81bf-579a65cfebd5	07:45:14	17:30:39	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
63b8a271-e19a-4b3a-8aa9-32e6951b372a	07:46:19	17:37:47	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
faebb421-1355-45d5-9798-91aade0044b6	07:48:39	17:32:03	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
442ea378-4718-401f-942a-ce1eb6cb5559	07:52:18	17:36:09	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
50673d28-5cf6-48a7-bf65-669442b23140	07:55:02	17:37:59	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d662a638-15b4-44f0-b278-58377ba4ba15	07:52:47	17:40:08	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
24418d25-f4e8-42c6-b38b-485b9d5e7fa1	07:55:50	17:31:33	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d8d6ebf1-764b-493f-8260-8a510632935f	07:51:41	17:39:48	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
776cd66e-aca5-490a-8cdb-7dcf572a0fd4	07:58:46	17:40:21	SUFFICIENT	2026-07-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
bc16de25-2b0f-43e3-aac3-ccd16283527d	07:53:03	17:37:51	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a59eeb29-4680-4f2e-a06a-55398387e029	07:56:14	17:49:55	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
0cad30bd-38d0-4385-b578-1bbca3d168e8	07:50:11	17:44:40	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
95243067-d3aa-4e52-8b55-83618b07468c	07:58:31	17:32:12	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
dfe02a7b-40db-4fd7-a5a7-1dd97c16b144	07:47:13	17:34:05	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
958ec56b-a5b9-469c-bd2f-c2b8f5cc6cc1	07:53:53	17:36:15	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
0da9f611-4f28-4c14-be30-d07c8dd3bc10	07:51:46	17:44:19	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
63db5e6f-269a-463f-beee-4f5a26a5476f	07:48:15	17:43:11	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
2f96bb75-a671-453e-88af-c002fbacc299	07:49:18	17:48:28	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
15354aa6-91f0-4102-9a54-13679435b21b	07:51:17	17:15:05	EARLY	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
f1489f15-17ad-4fa6-8d8d-7fafaf40431c	08:16:25	17:42:10	LATE	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
6c208589-a091-4b29-9f81-79de9f064d3d	07:51:32	17:49:47	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
7f50f361-7b8d-4dd6-905e-09d9e8bb3f0c	07:47:52	17:45:01	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
c90988e5-ff4e-4ed6-b90b-f5cd464f9f2f	07:51:54	17:32:48	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
98d7adbe-f01f-4e71-ad22-9ad88d52db87	08:14:38	17:34:35	LATE	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
72ce3c16-fbb5-4ed4-b0d8-67b1517a9800	07:49:24	17:44:19	SUFFICIENT	2026-07-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a15ad8a5-93da-47fb-a7b5-8dd917eed3a1	07:51:35	17:49:30	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ba33556a-4539-4b76-87a1-ef4d829bcd03	07:47:45	17:45:12	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a52a1465-d3b1-4cd5-a5fc-fdd7366aa865	07:48:00	17:30:55	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
99501c47-8b49-41d4-bfc3-efe1ee08a3fe	07:56:23	17:45:25	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5c370ed2-3d5a-4c57-87f5-273b14093df8	08:35:25	17:41:24	LATE	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
8aecea32-1e78-4cc6-a8e9-cbfc7f199246	07:55:37	17:32:26	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f899c3eb-5c34-4171-b53e-2672d4cd8f6b	07:59:07	17:42:59	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
02267103-1e06-492d-9d76-c3fa8284a9ad	07:48:48	17:43:16	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
b9d53dbe-b07e-480d-8099-c802672e88b5	07:57:46	17:41:32	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
08f49d31-dc94-42e5-a5b8-3ecd9b30e012	07:55:44	17:41:44	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
beac8079-5aa2-4f93-b88d-24f62613484d	07:51:59	17:43:47	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
c7067499-ec2d-45f6-afe5-63cab52439b7	07:52:02	17:41:40	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
7a56af09-85c7-47f7-90b7-e9def7cb8325	07:45:44	17:50:09	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
697d0f9b-3884-43f6-8618-f94c92531de4	07:52:43	17:34:16	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b175b853-c044-4f07-9ea9-8ee63d168ca4	07:54:42	17:35:00	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
9ebe251e-b56b-4f26-ab77-409ee577d1b3	07:46:41	17:42:25	SUFFICIENT	2026-07-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a68f7d01-27d1-4de3-96ea-7da1388a92c9	07:59:05	17:46:58	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
f68a20ca-9774-48bb-8483-dae03cf85c13	07:51:10	17:43:16	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
5beae289-c131-4ebe-b8ca-fbabdbf183e8	07:53:34	17:42:37	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
85644fab-b995-4c57-b6e7-5469725da723	07:51:48	17:32:06	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
2da53a3a-0ed1-48ba-8d41-b735a4bfb5f8	07:57:51	17:41:52	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2042228e-9ea5-43f8-a7a1-2b0fb019392e	07:56:13	17:42:44	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
45679eeb-0699-4643-8188-e35a4cb4f52f	07:47:52	17:45:00	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
68c66747-3de6-4e03-aa29-d80384847ea6	07:57:44	17:43:33	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
2e8547b5-86c9-456f-8b18-e7126136ffdc	07:49:46	17:43:10	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
1df903cd-f014-450f-80e8-43ce0dc1460b	07:47:45	17:34:12	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
08b440f5-ce96-4768-9b2e-968761f94ccf	07:53:07	17:44:36	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
9e870537-d1ba-41aa-87e7-c359a78f8923	07:47:12	17:31:47	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
a872ea4c-c1d9-453f-bd43-7fc10f14fdf5	07:57:12	17:38:57	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
0f71a47b-e9f8-4a63-b0c0-6fb16bd34e3d	07:52:40	17:49:06	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
cf7a9914-a5ee-4335-b6df-29c373f73b92	07:47:05	17:39:05	SUFFICIENT	2026-07-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
d9b14356-6960-48c8-8f51-4805142b9661	07:49:04	17:40:01	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
cf095402-ff37-4b09-a195-20cc851de535	07:52:31	17:33:00	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
c6699bcb-09d8-4594-a1b4-ea6027e3f77a	07:57:00	17:48:50	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
dcf26abc-d3a2-4c29-95ed-39691a6f310e	07:49:13	17:00:24	EARLY	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
46286a1c-e2de-43f1-a8c5-97eae0a6bad2	07:57:17	17:45:30	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
33800f6b-b74f-4eb6-b931-ab0f709a4650	07:54:27	17:40:23	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
84684402-e3f6-4a30-b6ca-011cc9731f0c	07:50:20	17:37:23	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
fbd0c268-da1a-4166-8ee2-be77ccb334a2	07:51:39	17:31:22	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
38658783-9109-474b-a088-b56eb32fb889	07:57:06	17:30:29	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
72241072-7c8c-4478-b35f-9db1639f3f42	07:51:46	17:34:01	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
5fee782c-ce25-4647-8c11-fbab862c6b87	07:58:33	17:38:44	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
8439e38d-4344-4ad7-98a2-ca88db7fc5ce	07:48:23	17:44:39	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
da8a92aa-87ff-4586-b068-6170a2a5fc2f	07:58:30	17:46:26	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
0b6024a9-f0d6-421a-b8b7-2f1a42e305f8	07:45:40	17:40:01	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
53229353-15ab-408d-aa86-1859552013ff	07:58:02	17:40:43	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
d61a7d8b-b0fa-4130-9278-8ace2175822a	07:54:31	17:42:47	SUFFICIENT	2026-07-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
6c5f8f34-6e8e-441a-9c13-c3f24dc491f7	07:46:22	17:43:59	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
46bd492a-4f8c-4eb1-b8b4-5b22e196eb33	08:20:42	17:33:46	LATE	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
ef3c9276-3845-4fea-a1f0-c75cc31b6735	07:54:12	17:34:55	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
04b0910f-ab19-4a64-bedc-f2a490b87d9b	07:54:50	17:46:02	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
3c216cf3-d7f4-4807-b423-0a1ea8dc3910	07:57:05	17:39:53	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
bb8011f8-4d22-4f61-a8e7-74cef97206c2	07:53:55	17:44:10	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
1aefa5ed-19bf-4410-b3ed-70f8b244e2b1	07:46:30	17:47:15	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
e4a38763-cf77-4e09-91d7-a7be68b0c07e	07:47:48	17:32:06	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
428c3167-5622-406d-8b79-76db9c077773	07:56:01	17:35:59	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
2c0040dc-6026-49fd-9bcb-27f0e20422b6	08:33:24	17:38:14	LATE	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
61753e4c-79dc-4891-ac25-e04830f576fb	07:55:30	17:33:42	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f5118c28-a85c-4b23-aa00-484dc7481933	07:53:40	17:45:05	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
41049818-9dc3-445c-8834-73c363067f37	07:50:55	17:37:59	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
97bfe65c-00fc-407f-b5da-dcc9a0fa8cfa	07:59:38	17:32:41	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
866577d5-eab8-43cb-abba-b354ce8ff701	07:59:45	17:42:41	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
e1a2bad4-f381-45d3-b08c-c5a54fd58a5b	07:53:54	17:43:51	SUFFICIENT	2026-07-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
9cc031eb-ced6-4716-930d-31beecc7802b	07:49:07	17:39:05	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
1313d338-f14d-4da4-95ca-eb9f7d1b456b	07:50:47	17:48:59	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
28f790f5-beb3-41a0-a4d6-ca4a6a411d96	07:46:36	17:41:08	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a253842c-a7c1-4bc0-926b-f3c2909cd2d9	07:51:36	17:30:19	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
9273f487-7521-4d31-a3ad-69ac48c45913	07:53:12	17:42:27	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
2fa84224-97b0-46c8-85fe-0ed0a197b3d5	07:50:51	17:34:33	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
b088b169-5c5b-4261-8322-7893f4510cf2	07:54:14	17:33:25	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
67197724-9508-4aa8-84c8-0fa010143fb6	07:58:29	17:40:09	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
9576a555-8405-450b-9552-2c0e220b743c	07:49:53	17:37:31	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
bb080432-f651-4230-af4f-879f96bf4fff	07:47:38	17:39:09	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
987565e1-9782-4646-909b-104e0ec311d5	07:58:51	17:31:38	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1f07e805-2cf8-48b1-b144-593980324a73	07:53:44	17:33:17	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e179aa0d-65d8-4029-911e-b96719a93594	08:20:40	17:11:31	LATE_AND_EARLY	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
b682defd-3e83-4b9c-b1e4-f64969790f2d	07:51:03	17:40:09	SUFFICIENT	2026-07-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
ab2a9976-f89b-490f-a92f-d3d21e044b5a	07:48:54	17:37:44	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
9f752338-9ab2-4156-847d-e3f53c4fc553	07:59:55	17:35:54	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
db1ca3d7-8a22-4649-b911-147cb344f369	07:51:19	17:35:01	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
9d208c43-3dc1-460f-8ba5-8042666f6b1f	07:50:27	17:45:22	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
c579e230-aef4-45c7-a334-9ad4f1db3b95	07:51:04	17:46:46	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7bdfeeb4-2c82-45b8-801e-e52eaaea3617	07:56:59	17:36:44	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
29e8b078-b965-47e7-b258-a5c121355d78	07:51:06	17:34:20	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
e325f3b2-30ee-472c-9ee8-3fe74ae8d00a	07:54:55	17:31:54	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
62aa8974-3cf9-4aaf-9cb3-9731648fef4c	08:14:29	17:35:36	LATE	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
ea9a2e98-ea86-4631-912c-30486654af58	07:56:30	17:39:57	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a556cce6-cfd5-43b2-8e5a-1384f898f707	07:48:51	17:36:47	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2ea53474-4351-4d01-bfdc-672f6ef47a58	07:50:46	17:48:06	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d1957bd7-7776-4df2-8d94-fb4c9a4ff55d	07:58:09	17:42:27	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
dea31185-ae3d-499f-99e3-6a457aa819f7	07:47:59	17:31:06	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
307794b6-2488-4157-8648-a286bf85e32d	07:52:11	17:31:07	SUFFICIENT	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
3be54a16-7552-42f5-a07d-f577332c82bf	07:58:21	17:13:09	EARLY	2026-07-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
1ed95273-7109-40a6-87b2-5373e3d1ed5f	07:51:15	17:31:07	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
2ae8fcf6-2f16-4b89-b963-b6767d1c444c	07:52:19	17:49:11	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
ca1dcbac-89f0-40fd-99e7-cafe6519c8eb	07:51:49	17:32:49	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
4e90805a-4adf-45d3-a645-0a139d86c730	07:58:41	17:42:17	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5c2963e1-1c37-4dde-93fc-fc512c129a8b	07:52:23	17:30:07	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
bd7b5e69-b4ba-4048-ade7-72fec4e7056b	07:46:31	17:50:42	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
cf776a59-ded5-49ec-ae73-d2b833aed878	08:12:01	17:45:17	LATE	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
b365a035-5a77-4070-af8d-fd96f678e493	07:46:50	17:48:11	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
bf817c64-dee2-4f82-a9ab-c0d03ce9e0a8	07:55:44	17:43:19	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
71653f78-286c-4b91-be57-3af7bdafe311	07:46:20	17:32:45	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
d5628f70-75ce-420d-9ec2-3fda1543d18f	08:30:34	17:35:25	LATE	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
c5ae3c55-7a1c-4ffe-80ac-cabce849a976	07:45:25	17:47:52	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
f20325f5-8ec1-4eac-9390-80ac929c8c41	07:57:33	17:45:04	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
775cdf36-754c-40bc-b29c-5ec80ec8375a	07:54:34	17:50:07	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
7c19dc1f-6271-444b-b6c4-b839ee8857bb	07:48:42	17:33:11	SUFFICIENT	2026-07-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
4b73d94d-3a4c-4d4e-9345-a056e7e50cb3	07:56:11	17:30:35	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b2b3cbc6-eabc-4f62-9f3b-9d28b7bd684f	07:50:07	17:31:08	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
df6908f1-76c1-4962-a0db-daff9f9c86e8	07:55:10	17:32:35	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
55fd4ecd-fcef-4948-9b67-b6977bdfa8ac	07:57:02	17:32:07	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
c6f661c8-0325-4734-8378-2a7f0804d2d0	07:50:34	17:35:27	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
9d543767-46bd-47e9-b82e-2c524021d40d	07:58:00	17:07:19	EARLY	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ba6596d8-da9b-4d15-a8e0-3892cdaa3640	07:53:57	17:39:42	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
30097dee-7f26-4be8-90f1-8ef567771de5	07:47:36	17:45:44	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ac65be23-35dd-4241-bdd9-b89552733aea	07:59:22	17:49:34	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9ce48de0-bc89-493e-b5a9-bbb1175073c5	07:56:06	17:31:15	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
871f32e6-916e-4ec4-8d7c-ea54f2710a68	07:47:19	17:36:08	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
ce896f1d-4aa4-4dbd-9ab6-9d3d53521ac2	07:48:37	17:41:17	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
985f0dcd-a496-4639-bdd2-9870f7667f2b	07:54:27	17:32:35	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
e7345d43-541d-4870-8773-7e9b7b271a36	07:51:41	17:35:25	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
8ece0f0f-3525-45d5-b26b-44323e922afb	07:49:43	17:43:44	SUFFICIENT	2026-07-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
84f003ee-30c2-4908-9030-876dcbbcbc07	07:48:04	17:50:46	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d9804cfd-e056-47fa-bd60-2b260df19b27	07:55:44	17:50:12	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
5fcaf574-9987-497e-bca2-b2b90bdcbbf1	07:54:42	17:50:52	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
fd6f9d6a-82f9-4149-b31a-490f6435cc0c	07:47:26	17:34:20	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
b666e4e1-5d5d-4601-9397-7a3b7d7e7559	08:18:24	17:05:38	LATE_AND_EARLY	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f1770e20-a10d-4c38-844b-9b8adfd61059	07:49:07	17:47:07	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
c6e54bfb-0f1c-40a2-b479-f067f8e627dc	07:51:04	17:40:40	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
20617164-3bca-4cb0-9137-1fb41b4683aa	07:59:21	17:38:09	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
1553207d-8d21-4950-9c5c-53e9fddbd79f	07:48:17	17:30:06	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
d42e681d-554a-41cd-9be5-16e64f715e50	07:48:24	17:33:50	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2432f6dd-ce8b-4f63-b8c4-aa686b076777	08:10:33	17:39:37	LATE	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
b08bdf50-0d2b-499a-900b-ad7dca336e58	07:52:06	17:46:22	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
e989f52d-2445-45da-a04c-e9d8bc983301	07:58:18	17:47:17	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
802ba36d-3df9-40a9-89ba-cfcbdee58fe3	07:59:03	17:35:20	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
4e2c3abe-824f-4d4b-ac44-d7cff9a084de	08:17:11	17:41:51	LATE	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
87cb787e-8dff-4a13-b9fa-9b85ff5b1613	07:57:34	17:47:38	SUFFICIENT	2026-08-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
9ba6a92a-e948-4627-942b-c2367678a663	07:51:30	17:48:08	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a23b6d56-05e8-4622-8eab-4dfa4fdb7cde	07:55:32	17:34:42	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
f283d2e1-9daa-472a-a1d1-683d6e95a11c	07:51:36	17:38:03	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a5f1a9a9-9ba6-4b80-bc2e-b0a44225955c	08:25:23	17:37:43	LATE	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
cea5db28-20f5-4ff8-b362-850a71a85182	07:56:29	17:35:28	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
2babde3d-dcbb-4d36-879b-e313939374ba	07:55:32	17:09:17	EARLY	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
2e1399a4-088f-42e8-adfe-a3b4f969e17d	08:21:45	17:37:19	LATE	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
cdcf1c73-c298-4f4e-b21a-9438220192b9	07:46:19	17:43:49	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
3c426ea8-e4f8-4156-aac3-e7eb90319c09	07:46:40	17:32:04	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
dfda611c-f5b0-4ea6-b786-c3b8e8f146c6	07:46:10	17:48:03	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c9deff77-79a2-47e0-bb5b-74268c81c1dd	07:49:35	17:45:51	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
05d4a041-31ec-49af-a7cf-ed0170f228cf	07:51:43	17:46:59	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
768518ae-e734-4c2a-9974-e78d45419bb1	07:52:31	17:46:43	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d7502ec6-aaea-4b53-bcb1-a1a9a87b2516	08:08:25	17:05:39	LATE_AND_EARLY	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
3ffe5578-44e1-4447-b384-785c1a74f675	07:58:47	17:30:45	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
fabe0549-4527-4289-be6e-493cf5ebbf7c	07:53:47	17:41:15	SUFFICIENT	2026-08-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
1df2a2dd-d107-4dac-85a7-614ff8183c43	08:06:38	17:19:10	LATE_AND_EARLY	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b6776b74-9625-4966-b6ba-a8601c7262a4	07:59:48	17:46:57	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b7538b65-2d43-44b9-87f9-a7427755478a	07:46:23	17:34:32	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a5711415-dfd6-473e-8c45-dc4d5b832a9c	07:45:27	17:45:24	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
51b73eba-fd29-4f29-9bab-5684c8b9220a	07:46:21	17:37:53	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
1e809183-10a7-47d0-b44d-7de9f9be0d8f	07:57:54	17:33:18	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
55936a28-1dd3-4625-956c-51432b59975e	07:49:16	17:36:00	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f067cc83-fc5a-41ac-9c5b-ea7686a517fb	07:54:25	17:36:59	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ed4fa7ee-7fad-4848-be3f-95932521a0d4	07:59:41	17:46:52	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
fcc0250f-3206-4d4e-813b-400afd618da0	07:59:29	17:49:54	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2eefe07a-4877-4a98-ae90-4a12fdf21e18	07:50:00	17:49:29	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
79fe096f-9f4f-4baa-8e5c-ae7c20516e76	07:50:06	17:30:22	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
ad49496a-35a3-4aff-8ff8-46ab24e65477	07:47:25	17:41:00	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
bb79b7c8-a067-44f5-a14b-9e87408f9f0b	07:52:12	17:32:33	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
4cd93d70-1025-4b1c-923b-1461c4daa38d	07:47:26	17:33:58	SUFFICIENT	2026-08-05	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c7b8bced-8440-4156-a6f2-030dc55ae062	07:47:49	17:38:14	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
919c8de3-4154-40af-bd03-7c68f94523b4	07:50:19	17:41:27	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
8b3e95f2-57bb-482a-b5d8-f9bf910f22e9	07:53:51	17:38:06	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
90c7c326-2a36-4858-9676-56965cf4fc79	07:58:53	17:14:10	EARLY	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
5c0e8118-53a8-4398-9146-0419da7743f3	07:56:27	17:30:22	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
9b2d3560-dc4d-4d2f-8384-5d57e5c3ca06	07:56:12	17:33:12	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
7f53a36c-7196-4bd6-ba21-19f61371959e	07:47:25	17:43:47	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
24f6520d-344a-4f44-9eb2-e94fba40d5d2	07:45:10	17:36:30	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
0d9a0bd0-af54-439c-b67c-bf51d33fb3cc	08:13:07	17:43:31	LATE	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
45f7fa4e-1e1b-4d6d-affc-391973b9bfa8	07:57:43	17:34:20	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
4bfb31f0-d041-42ec-aad3-0c6d2b5032a1	07:57:56	17:42:32	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
ff87219c-0774-4f37-82d8-4bdab772767b	07:56:53	17:42:08	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
899664ed-af82-41a9-be67-83bba4117d3c	07:46:50	17:30:08	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
035114c6-ba66-439b-95ff-1de469051ed0	07:53:00	17:37:03	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a3f588e9-29fc-47e7-81ad-9572f83e066d	07:50:27	17:49:47	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a885c55d-ab0e-4053-808f-69d763788584	07:52:18	17:39:31	SUFFICIENT	2026-08-06	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
365c3a62-3b8f-46ba-b422-e57505054d6c	07:51:15	17:49:09	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
5370645e-4a6a-4bbe-8130-efaf98a47fc9	07:47:15	17:38:49	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
25dbd8b0-7cc0-4006-82fe-11b59635a653	07:49:44	17:37:42	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
c85d08d7-fe39-42ef-b5cb-eb91f66b2626	07:48:30	17:33:44	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
9ff0c540-917c-4d68-8d51-6b0dc988dec2	07:54:11	17:36:54	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
da953439-a683-4875-89bd-6476c46ac2f5	07:55:09	17:37:07	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
2ef8e69f-6c83-488d-9b0c-0452b0699ca1	07:45:17	17:36:59	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
23f2ef15-1100-49b6-a800-87c390e02fde	07:45:39	17:36:05	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
d1f2c510-75f1-424a-bf94-23e46d5fdaae	07:51:26	17:46:19	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
afa2ba99-10bf-4c2c-a549-be2eb5bc315e	07:48:14	17:40:27	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
40b864b5-9874-4eeb-a92f-a97c87fd42b7	07:53:27	17:50:03	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
99447072-a5b9-4dcd-995e-4f825ba598fa	07:49:23	17:38:22	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
8e8b9abd-b7e7-454a-9796-2c98ec2f7f1e	07:48:20	17:31:11	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
5df8f030-c817-4a91-8902-9e577a09061d	07:45:42	17:40:13	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
02c7e7dd-2295-49c6-83cb-c02303c985d2	07:49:58	17:49:06	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
29bdabef-940a-4f47-a980-f2f020124b78	07:49:31	17:41:21	SUFFICIENT	2026-08-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
d1e0aced-e7f7-473d-95b6-0c6cadafadb2	07:46:42	17:30:43	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
36bb5fd3-d239-428f-bbab-f1c56caaba6a	07:58:08	17:40:23	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a0e99f47-c79c-4c35-9d57-f085ee18ea2e	07:50:47	17:48:33	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
c2cec94f-39fa-4120-96ee-9cf4ab5fd5f7	07:48:41	17:38:13	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
7b6ffefe-125a-46b0-b906-8ef35903f61d	07:46:56	17:33:08	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
0dd48b7f-4a47-4763-a02d-0d7865c1fa23	07:54:07	17:31:37	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
1ae5531a-7dfd-41bf-b726-315c463fc509	07:58:52	17:06:12	EARLY	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
bfc602b9-b6f5-4066-8cd3-3e754350da95	07:59:06	17:32:34	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a6048c4c-33eb-4825-92c0-d761f1d21bef	07:49:46	17:45:48	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
4d03a572-9caa-46c7-987e-b640dc8b29a9	07:56:09	17:31:08	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e50a66e2-0962-41e9-a4d6-905ac689e389	07:53:45	17:38:57	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
fbeeca70-8341-437e-8b9f-23222e3326eb	07:58:54	17:47:22	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
33b3a9b0-f02e-4b7b-a04a-ce6a4c0e9b77	07:52:40	17:33:58	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
40075e86-e27e-42a6-a5c3-209ff016b53e	07:52:26	17:46:59	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
f75b0483-09e8-411d-9d63-48d5c8946501	08:30:01	17:35:38	LATE	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
1254e119-4482-4ea1-8bb5-2803c0aa3087	07:47:18	17:31:36	SUFFICIENT	2026-08-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f2740c85-cc8e-4c04-96ae-0257d6581879	07:56:12	17:42:31	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
29f9b2d2-cbec-4668-9573-cfe8bd75a85c	07:58:32	17:32:10	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
22bc226d-5b3d-4aa8-a27e-1ed4edc97be5	07:53:24	17:47:49	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
54ced482-1c43-4e4d-ade4-e49f93c595bb	07:54:17	17:36:11	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4d45056f-d805-441c-9f99-4593a02a406d	07:54:13	17:48:44	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f8a0688d-b447-4158-8eed-f20415619f09	07:59:50	17:46:29	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f43419a2-c205-4c0f-b347-e4eda38acb85	07:56:33	17:38:19	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
6cafeb36-f3d1-45c5-adb3-5f2f59586160	07:49:45	17:38:35	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
059d81d6-414b-4d6b-b9a3-b7c3101be4f2	07:48:02	17:47:15	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
440bf323-c1d7-4e64-9b91-ee822627d40d	07:55:09	17:38:59	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
7a5f5f1b-bfe5-42fc-b116-d4c77238cde3	07:58:50	17:31:41	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a3b759e8-a918-454b-9e6a-7f8bc949963e	07:51:34	17:03:00	EARLY	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b2476bf0-6fbf-482b-ab33-4596a6b49400	07:55:38	17:41:20	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
4338702a-166b-4a94-bf4c-f4a36e41f920	07:56:56	17:47:16	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
648b900c-89d3-426c-88e0-c8b6cf3d8a69	07:51:57	17:49:18	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
d4df073e-1a46-4dee-853a-9e17dd214ded	07:45:40	17:30:52	SUFFICIENT	2026-08-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
d0f38b61-1780-4ef2-b81d-85199aa05632	07:56:17	17:35:16	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
a6e2c04a-2137-4f72-bff4-3539ed2a8301	07:56:42	17:03:46	EARLY	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
33eb02df-0d17-450e-ab00-5ea4c88bd3e3	07:51:41	17:38:55	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0e2e24f0-9216-4178-ac4e-5e16fc6919ef	07:54:35	17:36:52	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
2a3d00cd-16ef-4b34-b401-93be144889af	07:50:17	17:36:37	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
1460b594-1b93-484e-948f-821834fffbd5	07:58:48	17:42:09	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
091ba7d5-7a29-4739-9685-4979fc12e9f9	07:56:46	17:43:23	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
2158d8d0-b2c2-443c-a4af-95fc318a913b	07:52:05	17:45:11	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
973fd2cd-cae3-4d93-9fd2-accbb59c0892	07:58:55	17:35:12	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9bb5e037-7452-454c-bab1-5b593226c20d	07:56:11	17:50:18	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
d3b5b43e-0623-4300-8a02-f273d8f230dc	07:47:56	17:35:52	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2626007d-13eb-4210-a4bb-272c63de8e41	07:54:12	17:32:09	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
99138777-af71-4f65-b212-053c1179fd8d	07:48:29	17:50:25	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
91650de5-bc0c-4e72-ba0e-b773e1f87337	07:53:08	17:30:38	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
4ae19e11-239a-4d73-9c48-c5af024d768a	07:51:01	17:33:52	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
8fff1b5c-4189-4136-83c4-27a65a804f5d	07:58:41	17:31:08	SUFFICIENT	2026-08-12	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c7c2babf-6f61-49c2-914a-9202eaa5b049	07:46:17	17:34:40	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
86e80f43-64fa-41d1-ad41-79855632b1f6	07:57:00	17:33:34	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
8b198cc8-3ff4-4d8b-a2a3-9c79ca538b10	07:50:54	17:32:12	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
32fe9655-abfe-4397-938c-7e885076958b	07:57:36	17:44:52	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
4ae3915c-5760-4cf0-8c28-f30d966884a5	07:50:30	17:34:15	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
dc51f090-0de8-42e3-a25f-fa9575784265	07:56:17	17:50:34	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
79832efd-e384-400c-9a9f-bfc00b6f9a68	07:58:02	17:33:34	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
b336a7f3-bc1d-485e-9697-65c1adecf610	07:53:56	17:43:09	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ecbd8e5d-34f5-43c0-bd4d-83580f01d83b	07:48:01	17:37:27	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
65833140-2652-44d2-a738-cfee5dab502f	07:50:41	17:39:14	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
9af0494a-2c83-4b3c-b022-d5844e74b041	08:26:24	17:33:31	LATE	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
92f872d3-6361-4a67-9f99-d10b66ffad46	07:46:14	17:33:18	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
373882c4-c068-44e1-9d0a-f172e174d856	07:54:21	17:33:23	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
c92af9ba-3365-4254-8d66-ae52e5458819	08:34:05	17:31:38	LATE	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
372d8c5a-1aaf-4e31-905e-d7daf38c9a27	07:51:33	17:40:38	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
c4136163-26c5-4d4d-baa2-ae4e20f0aa3e	07:51:09	17:39:39	SUFFICIENT	2026-08-13	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
51c57a98-22b2-4cfe-a415-c6d013bb25d8	07:50:56	17:33:17	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ea35d8d2-24ad-462e-bb35-fdafd9508bc0	08:26:23	17:38:51	LATE	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
3c28bc48-63ed-4a14-b652-b14b5dcc1562	08:30:04	17:30:55	LATE	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
a5e29c35-578b-4045-8232-a836b81b0404	08:09:49	17:34:20	LATE	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a6e20acf-732f-40d7-9c15-c76041418de0	07:52:46	17:45:52	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
b30f1453-e7ce-4400-bc70-376d4fe518d4	07:54:27	17:38:09	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
819b5725-fbd5-4d46-854c-f93dac92a4ba	07:47:11	17:42:22	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
3df3d4c4-4376-4704-bb40-7f2c744e4845	07:51:30	17:43:38	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
11e8aed5-cde8-427f-8766-17afd237f76f	07:50:08	17:50:58	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
07b886c5-a90e-43ae-bc8f-b9ccf8d7eb5e	07:51:35	17:45:34	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
3570f0f8-66de-4d88-b88c-779cce4a6003	07:53:34	17:37:24	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
798c6c04-8f71-4ef3-b2d6-ed6021ad6564	07:56:26	17:46:36	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
52c41ebb-cbe6-4faa-953f-2a3de5d032ba	07:57:47	17:37:44	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d39ca54f-0cda-4811-bc75-4de5fb233944	07:50:00	17:36:54	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
2d0c4f56-3ee3-41aa-8830-ea4709dc99b3	07:53:30	17:34:58	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
ed672a58-2bfa-4f1d-a869-141050868bda	07:59:22	17:41:54	SUFFICIENT	2026-08-14	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
dd557e80-c266-4a68-854f-e9ec7163317d	07:57:52	17:34:18	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b295a5cd-47df-46e7-acef-06903813a86d	07:58:54	17:47:59	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
d797de3b-64d2-4b42-8f4a-937c7fb93a18	08:12:13	17:37:03	LATE	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
386c2b28-1699-4b81-9e37-d21b4249b11e	07:46:44	17:34:24	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
478e287e-f376-4d65-aad5-fed20d608a22	07:56:27	17:41:03	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f8c900bb-48d2-45c0-a3ad-513fa86f5d65	07:55:37	17:32:30	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
133588ce-8df1-414d-abc7-010396158aa2	07:58:10	17:30:09	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
951aaa2d-f90c-433e-8608-c89f827e12b4	07:46:15	17:32:00	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
881450ee-902d-48ac-8b77-6427e9268d36	07:58:26	17:34:48	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
3d787ca8-687f-4464-a047-6558e3fb03fe	07:56:08	17:46:44	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
27bf5c3a-30bf-45d5-8685-74bdadc920fc	08:20:26	17:40:28	LATE	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f446f930-7941-47a8-94ca-2ac8e172a9b5	07:56:00	17:39:07	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
c898e90a-e5ac-4bcb-a8d8-3036041013bf	07:59:41	17:31:38	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
0209e1df-6b7f-478d-94db-d1d12932833f	07:53:10	17:30:25	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
cc0f83e3-d905-4bf3-8da6-aafaadfb3506	07:55:56	17:44:35	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
36291d14-840e-44e5-9704-0e51d89e3b07	07:49:58	17:48:32	SUFFICIENT	2026-08-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
ccd27426-6e30-4054-9c38-e8a3b006a9fe	07:48:27	17:35:17	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
27edc0a8-72e5-40a6-9942-e77f2326df79	07:56:24	17:04:47	EARLY	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
35bff845-9403-4761-89a4-637196d83576	07:54:03	17:37:25	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
53baedcc-4d0a-4540-a36b-1424751e23f1	07:56:35	17:49:53	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
ebb44bd3-ae48-416e-961f-641a7d518fa8	07:56:29	17:45:20	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d44020e5-fbfd-469e-a0d0-f4dc9e77dcec	07:51:52	17:42:10	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
eb2a341f-7a9b-44c4-ae7b-1d3baba7a736	07:50:41	17:43:12	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
595f2c2b-3509-43fe-96de-e44d1e5a1777	07:46:04	17:41:38	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b6dd2480-2b70-41e2-ab12-53ba0f7b93a1	07:50:01	17:37:18	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
635ad2e7-3921-4e94-b4cc-b67410fe7925	07:46:04	17:36:38	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2f60fa13-10ab-4855-96fb-35e5edf643d5	07:59:19	17:36:35	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
9e3d2994-668d-4166-a795-637315f1cf49	07:59:02	17:37:17	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
3bd54361-bcfb-422c-9892-166676be4e82	07:54:36	17:31:36	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
777f1280-30be-4ed6-9154-bb8f0262f879	07:55:02	17:01:20	EARLY	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
7ceefc21-416f-4236-9a44-8dc0a44e1fd8	07:49:00	17:41:48	SUFFICIENT	2026-08-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
12342e43-ed6b-4570-b1fc-a05764efbc04	07:51:32	17:36:20	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
8c826c9a-ea3a-41d5-b8d2-623e54781f28	07:56:22	17:34:44	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
9b8b8e07-6cd9-4cea-94fb-35d3516fbf54	07:50:26	17:46:06	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
e3e21b26-fe4f-441e-a8ac-0fa6b5ff4072	07:57:09	17:30:37	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
3c41af0e-3afc-4b9e-8f56-3e6b72e0bde9	07:52:37	17:31:18	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
fdb4af09-42ce-4045-9372-66d3725e0d0e	07:55:29	17:32:56	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
9156e087-ddf3-4ba6-b674-1415081518fa	07:56:14	17:36:51	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
242a2730-64c7-43c6-8379-859ed0058398	07:47:49	17:35:32	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
98c76900-651d-41e4-9d8e-92674b3ee868	07:56:38	17:50:33	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
5421da65-14bb-4b06-aaaa-8ee499b83ce5	08:15:28	17:34:21	LATE	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
8f62dc83-225a-4f81-95e4-da1081a7342e	07:54:54	17:43:02	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
7fa49690-3f9b-486c-9fb5-77067b2ccb85	07:57:43	17:42:15	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
f852394a-47ef-4fc0-a446-f58fd80c8f8b	07:54:38	17:32:09	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
9c149d39-f709-44d9-9581-ea43e0a09929	07:52:06	17:30:09	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
092f626d-5558-4a31-8354-12735ba138e0	07:49:35	17:32:31	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
127e66fa-7528-4ad7-bebd-32146ed75853	07:50:10	17:39:10	SUFFICIENT	2026-08-19	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
06d36b6a-49ca-4bfa-be90-fad4ca3494ff	07:54:23	17:41:05	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
bb0cac0b-bf38-4d68-9f88-224b191fa8b7	07:56:49	17:44:16	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
808c7c83-87cc-4e44-b5cb-4569737a7857	07:52:48	17:14:41	EARLY	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
365b88a4-ed49-4602-8fdf-18a71311c79e	08:35:07	17:45:02	LATE	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
fddd3e53-29d0-41a6-a5da-47eab1fb5193	07:49:25	17:43:54	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
badacc22-fdc5-42d2-89b8-4cec9a629a16	07:55:08	17:44:23	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
bd6bc364-51d3-4cb1-a714-0558449ce179	07:54:20	17:41:05	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f19ea8f6-8fa6-41ae-90c3-23394f6d80eb	07:53:28	17:38:56	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
02bc58be-54b6-4f31-be70-5af8fb25dbe2	07:55:02	17:49:41	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
df92058b-ae49-44bf-b5d5-8a86bee3d755	07:57:15	17:47:00	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2b7ff22c-85ff-4108-aa53-b1564f94f49d	07:46:18	17:42:10	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
7a4aefe1-de8f-4b21-9eef-785dfda901b0	07:58:04	17:37:24	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
85bc088b-70e7-493a-895e-5aa7bfc874db	07:55:05	17:41:29	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
386136b7-9340-4191-81b0-7c357dcda84d	07:53:57	17:44:06	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d729c6e9-2727-40b3-b0a0-245b296fde3a	07:56:06	17:42:49	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
ac6fe7d3-9993-4f35-a341-17336ba77127	07:51:21	17:32:20	SUFFICIENT	2026-08-20	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
babf579e-492b-464a-921f-d50fa7240c9f	07:54:31	17:36:44	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
57da5db2-d0af-4a61-abf9-7ba5f8b2e5ac	07:46:17	17:44:02	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
e566ad77-0707-4a60-ab0f-1b07791379bc	07:52:09	17:50:13	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
0a736fa9-1a4d-4a43-acbc-9c75dc9c4069	07:45:38	17:42:03	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e909a379-2e57-44a0-8463-548cf250be61	08:16:50	17:43:30	LATE	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ecbcea15-e7a8-4a34-859f-869aa44369fd	07:48:55	17:30:48	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
76c3dff3-ecdb-4903-8b69-675cfb3d26a6	07:49:16	17:50:11	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
19c093c6-f53d-41e8-8c94-82e67fa3e5cf	07:46:17	17:42:05	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
13899086-4622-455b-baa4-d7147f595b72	07:56:28	17:43:33	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
3c3c166c-e4f0-4c5b-8d9e-534bab6dfc34	07:59:16	17:35:53	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
44d6ef3e-80d6-4bc6-82ba-226aa2767a6f	07:59:57	17:43:21	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
64edfc41-0fef-42d7-b736-3749579fc7da	07:52:10	17:06:22	EARLY	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
9a8e53d4-5bc0-4efd-85ce-07e0de314563	08:20:30	17:35:44	LATE	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
cd3bbe04-cdc7-4cc5-b0d6-f9e74c0f8ae2	07:59:44	17:48:24	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
2a4a7426-1b08-47a2-85ba-845d3d05bfa9	07:53:50	17:49:12	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
9f918e2b-0442-4c4e-8af3-291be20705a0	07:55:37	17:49:09	SUFFICIENT	2026-08-21	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a2ec252c-5427-46ac-8bf4-071f56c5e573	07:58:46	17:40:00	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c593b343-0ab4-4bf2-b175-4d091e4a7851	07:52:59	17:34:31	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
2bc5c24b-cf70-40c3-8121-df9db2bbfed1	07:46:50	17:43:16	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
b082d498-349f-4e7a-9198-54c9ededb03c	07:45:28	17:34:40	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
900e75b4-1dc5-4641-9a4d-a2932a2fb9b0	07:54:06	17:31:13	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
4db235ed-ddfd-4b15-96f0-764592fc2799	07:48:26	17:47:49	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
01791eb7-70dc-4174-9ef4-bcd05c2cde75	07:51:13	17:41:13	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
d16cda72-5658-4617-9ffe-242291c78f79	08:26:36	17:30:23	LATE	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f10ec27d-595c-4dce-ad6e-aefc067abead	07:45:19	17:39:32	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c64f9243-66e6-4754-a5de-d58243269275	07:46:44	17:45:41	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
2ad46b4d-ef03-4d21-84f3-c9e4e2307ee1	08:18:26	17:16:22	LATE_AND_EARLY	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
25c42181-a767-4978-a9a1-a5c8f817c89f	07:51:33	17:40:07	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
cc67c2f3-38cf-4fc1-83ba-7fd93cb84baa	08:19:27	17:41:11	LATE	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
61c6dcd7-a536-40af-9628-0551ba4f4aaa	07:47:34	17:43:24	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
24be8e93-a599-429b-bfef-bf27b4a5cf45	07:55:44	17:43:40	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f4843ce8-738c-4928-87cc-505b7188dc52	07:54:59	17:33:05	SUFFICIENT	2026-08-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
1cbc0213-e385-4446-b258-9d96047afa77	07:46:05	17:50:01	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
f624179d-00ee-4d76-97c8-30018dfd03ff	07:51:06	17:45:47	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a199699f-0a15-4ee4-af8d-b77e0309cc41	07:59:34	17:33:40	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d2bffb8d-4a6d-41be-ac73-9b7cf34f13ac	07:54:51	17:31:42	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
89ec912e-2bce-4eea-a93b-a9cca4cee203	07:51:13	17:37:49	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d7beb411-3610-45d7-9b17-e3f038e46d5a	07:51:07	17:36:54	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
2045a6f6-e816-43cc-9bb1-39f662ced834	07:46:22	17:44:26	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
c91bc0ff-de30-4e86-afe2-e2484108aa4e	08:25:45	17:42:00	LATE	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f23aa409-f3e9-4063-b9e5-c6348f85c59c	08:30:14	17:39:17	LATE	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
65970903-ec7b-41f7-a122-d4cbab8b08b4	07:49:19	17:43:43	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
6988553a-296a-49d2-b255-349156bd27c2	07:59:58	17:43:02	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
6f07c21c-919b-4a01-ba7b-87c25db1f283	07:47:50	17:41:53	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
9d05f15f-6e91-45cd-87fd-8b9961bc5a85	07:58:47	17:49:20	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
6e98b4da-2b45-4004-b62e-d38ca80c70ed	07:54:27	17:37:35	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
9924f283-2a9f-4e15-8a29-a386a45050cd	07:51:39	17:12:53	EARLY	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
8eda1867-1cb9-4081-912c-54d1c93443d0	07:59:36	17:43:08	SUFFICIENT	2026-08-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
53385e62-a5dc-47da-8b34-788eb0c0d05d	08:17:46	17:35:25	LATE	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ca839ba3-a9ed-4246-b2e0-87aa7086a997	08:21:10	17:43:14	LATE	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
7ba88c3e-c0da-4a18-bef4-b4c059b16753	07:57:08	17:46:07	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
69ee29ce-5102-47e0-a173-3064eb64724c	07:57:25	17:50:58	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
6fad6c67-7b4e-447d-a230-a86852acf282	07:53:10	17:40:13	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
06c3722d-1070-4ed9-8f79-f319f4ab5e54	07:45:27	17:30:40	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
c71a7cab-ef53-4704-99fb-48912651e120	07:47:01	17:49:45	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
5ac5581c-9dee-44f3-a6b1-f5e0b922d35f	07:46:36	17:42:01	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f2f937c7-37c1-487d-9cdb-76cb7080c44c	07:47:29	17:50:40	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b731312c-56c9-48a7-b52b-c0c99a6d5772	07:47:15	17:50:57	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e6c86c98-69cc-46eb-af6b-00cf016687ad	07:48:34	17:37:46	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
11e3d4d8-d11e-4fd1-a2d6-2f0cd59d1632	07:57:24	17:38:42	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
8a233339-2b8b-4cc2-9a1b-a26163b6a068	07:46:59	17:34:40	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
bd4c1d74-d4d8-493b-af81-81cde50c75c9	07:54:55	17:33:07	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
fc0ef25d-54ff-499f-9a89-a0e27cdfd9a8	07:54:07	17:33:09	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
50881ddc-f7ae-4dfd-865b-6661b25b6c00	07:59:11	17:32:04	SUFFICIENT	2026-08-26	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
af08d739-fbc3-4334-8020-291e2b0aa71d	07:50:58	17:36:25	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
fdf32276-ca61-4d5e-9ec3-4fc2bd69175f	07:57:01	17:43:04	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
43ae8458-a16b-4b97-bbf1-cd86ed80b074	07:55:04	17:36:43	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
907a1297-7c10-44d8-8332-5c88c107cfc9	07:59:20	17:50:58	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
88027590-6a67-4a7e-a672-12f33c7e849f	07:47:11	17:39:00	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d7c93a9b-ce8a-46ca-ba63-78615524675d	08:26:36	17:31:07	LATE	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
42740d91-7a60-4153-a2a5-d8805bc2b073	07:53:30	17:00:10	EARLY	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a2dbab43-e9d6-4dc5-897e-3c63dd2dd7e0	07:49:59	17:33:12	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
64804070-2b07-40e9-8661-00ad7f46bd33	07:53:01	17:46:32	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
eb548059-3f7e-45cd-be14-8432152a68e7	07:48:55	17:41:07	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
b797d538-9613-4d3c-92d6-9d79733ca8da	07:45:20	17:34:14	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
915eba74-9603-4292-84b9-46edf94bb2e6	07:56:08	17:38:17	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
b173ea26-a0c0-4993-a18f-eb509ddf37dc	07:46:22	17:47:41	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
9c38851c-5eee-40e7-b02f-76305dfdb0e8	07:56:51	17:45:27	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
cd52abc6-5022-444c-a0a0-9c8bf7a3297a	07:51:59	17:36:16	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
7f44d157-e83a-40c6-81ec-1b0da7e1e3e3	07:55:54	17:38:25	SUFFICIENT	2026-08-27	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
2f53533d-f7ff-4fe7-a999-a381cd8d313d	07:57:49	17:48:19	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
5b522818-40fa-43bb-9c4c-469a5c453cf3	07:48:46	17:45:27	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
dc974c52-f034-493e-85f3-06bf15f131f8	07:51:38	17:38:52	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
65e650ae-b100-4c90-b380-671911326227	07:46:38	17:42:27	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
d7802827-cabb-4d34-939e-fae8b9341eb4	07:50:23	17:50:52	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
1928ff2c-97ec-43d8-b4d9-671ebfc9d8fa	07:47:56	17:31:32	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
004afbd6-6814-49e9-8086-8129ad10fb03	07:51:18	17:49:52	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
26b5516d-2fcf-4820-a6cc-1fb93656c41f	07:53:22	17:42:01	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a15c59e1-aa3f-471d-9bda-fa3fd7e64624	07:57:20	17:43:50	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
8a6928a5-d15c-4d0e-a575-879f52fde420	07:48:04	17:36:42	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
ba5809ec-4ef3-44b1-a781-a3006ccbb85b	07:47:49	17:40:07	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
0ad295a1-2b91-4329-82a6-5a1d55c144a9	07:56:00	17:40:13	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
4d88535a-7a6d-4248-ba71-579724a94a34	07:57:20	17:37:35	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
27422927-3750-43a3-aaca-6f73c789230a	07:49:38	17:36:33	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
301b9b87-1fcc-4276-b9b9-09ceadb5333d	07:53:17	17:49:56	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
6a62cdcd-8ff5-4d80-b217-6562969a8cd6	07:55:04	17:48:57	SUFFICIENT	2026-08-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
1740f4b2-4eab-46cb-871a-5d7de8336159	07:55:48	17:43:20	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
221af454-1c23-4875-9c79-edef93e364b6	07:48:12	17:31:51	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
f1075b27-8c52-49d4-bde4-1d4d53a34e33	07:45:17	17:43:07	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e1cd62e6-37d0-4aea-9a8b-3d0cb3303364	07:47:38	17:40:37	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7f846204-1c50-46a4-83b5-390b75b4ad7b	07:54:01	17:39:01	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
0d42afb7-ba3a-4a52-90f1-077fe548e7ea	07:58:36	17:30:58	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
0e130a3e-d771-4376-9910-7339094fd781	07:47:53	17:42:02	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
120a7c5c-5682-4656-826e-7c78a7f2a605	07:59:33	17:31:21	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9ee41655-dafa-41a7-86b4-a87743fa1148	07:46:30	17:33:53	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
c8903285-522d-499e-83bf-c53f6007e3d6	07:56:19	17:38:20	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
fb41119a-4fb8-431b-94ed-91f63a309116	07:51:05	17:47:49	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
53bd3d02-b96f-4016-b3ef-de42c7c97724	07:54:03	17:42:19	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
10d6be21-f3a2-41f6-bf10-3bb1fa0ab6f6	07:52:31	17:50:58	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
42e2adb4-3b96-40ab-88d7-f98096df59d0	07:50:39	17:33:01	SUFFICIENT	2026-08-31	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
767f466e-fe35-44cf-8f38-e7de96da6db5	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
8e80a75e-7fc4-46f1-bd73-fefd74f9c564	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
0266ed5a-7995-4db0-8240-393e4201aa4e	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
dbf5cf26-8994-4c53-acbb-3558082d7b67	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
f8712f50-6d4a-4983-a68a-5fab6be6b41e	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
b894db81-ab3f-4319-8236-c5294e53b4aa	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
d4431d2d-8a6c-4b64-b4ea-01da9df0c14a	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ed60e043-0fca-44d7-b952-fdeb3cfb2aea	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
426ada3c-eee8-49c9-a612-fef90c1b211f	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ac34083a-38ae-4837-82cc-9e9fdc48f3ae	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
bf15db56-fedc-4210-9ee2-870263691a7e	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
af6a48af-af2a-431d-a9ce-2b7e6bfb50b7	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
c39e603c-c43e-49d0-b11e-cd77d0546c40	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
74a17855-599f-476d-8dfd-4f0bb1849dd3	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
4dcd054b-c2f2-4216-94c7-93eae560b570	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
ae8e54fb-7aca-4ba4-a2d6-aaf603b45e29	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
206f441b-2035-478b-8a46-cd587ab9485b	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
1448a5a5-c85e-4e01-93c6-d35e2af992ee	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
f5bcb15f-a07c-4a7b-b8c1-123e3ab4ad84	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
5f341c05-0644-4f84-8533-ac3fa6d7297c	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
e3e899ef-768b-4046-86da-45cb23c45da0	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
eb1878aa-6585-4537-a8d2-2ecd2298f642	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
202cb8af-636d-47ff-bb4f-dc7405e79d68	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
f3ba5846-e7a7-4e82-aaed-dc2fb96cede2	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
ff2cf3e8-311b-4b59-993e-2e2f45d3fd17	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
fc560189-8b08-4935-80f6-aa4060c9de9b	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
5dc962a8-5f65-40b1-b432-f27c837795bf	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
27628e68-20b6-4dfe-949b-dd5e52efa2d3	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
24a96e8c-f74e-4cc7-a79b-35b7dcf58897	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
24b671f8-5c41-4add-8053-9d12100de17c	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
b174f3ad-964a-4961-9e95-fb4f5c26c417	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
52db371f-b824-4c13-bb15-3817d0ab9f7d	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
5f6b3682-3980-4401-b1df-a5fcb974101a	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
d603d43d-3eeb-4569-9589-02dc93b34ee4	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
9a0da6c9-a290-4e73-af02-20f0fe7120ff	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
134c4bff-c258-4799-bcbb-294c181675fc	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
a76ba4cb-8c51-46f4-8310-72110db32eb2	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
d5f424a3-fbb9-404f-b0a5-16a90454f146	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
4c839191-d631-4204-b4e6-9bc4b4676043	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	f	\N	\N	f
33d83341-3c65-40f4-9253-0c908e30da13	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
0919f722-501e-4a0a-a6ff-6ecb03be6ff6	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
c67e53ec-62ac-4364-96c5-4cce0cc59a3d	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
c631c4c0-89f3-44ab-aba2-925a09ea686b	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1a3c3397-d247-4a1f-95de-60cbc38a5c3f	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1703035e-928b-4e6a-82e6-32b0a1846f37	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
5e2b0085-559e-4d76-b076-233145d47bc2	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
e39e16a5-516c-47aa-b81f-17b825d84c2f	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
dbf252e0-6535-425c-83d9-74b781de6e74	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
41f74500-3eff-48bf-a77d-7aee055c6e87	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1a5365ba-5423-4ab2-9fee-8096bff8156f	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
6522380f-f233-4988-a28f-40938c1a2fda	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
2e55bb22-9a17-48af-965d-9a7ef6cc7b2d	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
ce11b15e-465b-4002-aa4e-6963afa24ac5	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
6bac1333-e9d9-427e-be19-7ea02da505aa	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
44005095-db05-4167-88e9-3bb3732ef552	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
d8e0c977-ae4b-4de8-aff0-84a133e3bbef	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
77a950c6-d20a-4689-90d2-fc4ac0865b5f	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
082528a3-0887-4782-9647-b5adc6ad8486	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
f8556655-8722-4fe5-97c8-bb7dbf98a75d	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	f	\N	\N	f
1cf14d22-aa1f-4ae6-b2f0-cc9ca5301327	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
e653b2aa-bb59-4864-a31c-7a68902185da	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
2b8d7f15-eccd-46de-95a2-31bf8f989ad1	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
91fe0b2b-523e-487a-abd7-5b3c1c4a349c	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
a84b0f95-cf39-4350-9d54-ade78ab6c3bb	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
d0ed87d2-f796-47fc-b1cd-c9a1e0926dca	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
bde8de34-d4d1-47fb-b92f-27d6bc61c79c	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
055e9cd0-fc90-4291-84f1-90eb0c0b7230	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
8b724267-9fdb-44fe-93a7-3a9e0d9d2950	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
79f09da2-0013-4f0b-a2ae-e0d3b6a04a69	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
c23d6c59-3b50-499d-8e97-9ad935729fa5	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
4c0354c5-5a0c-44a2-b600-1542a92a1a17	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3f5cfa65-e18c-44a3-a41e-1bd7834849a2	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
24d7612a-c5f7-4ed3-a468-34c4e3e78977	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
ee61dfde-622b-4728-8ef4-a20dfe17bfa9	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
7399b42d-2465-45b2-95de-6749ce5401de	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
53a47600-5c6d-40db-8d23-15d2dc27d4b4	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
3becc74d-d72d-43dd-ba30-26115c5639cb	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
acfc91c8-ea6f-49cf-b99f-64944b5a13e7	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
86756478-a097-48e8-a640-81e65be7b506	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	35337165-e0d0-4dd1-9c67-cc48180363af	f	\N	\N	f
eede7417-ba42-4612-8e59-fed4441dd745	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
d6fa73d7-4a85-431a-b3dc-5f4073307e48	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
99f40724-add1-4bda-829a-ea9acf769e73	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
a34cf457-54c2-4d76-89b2-aa79518ecddf	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
ec03d366-f865-4684-8561-3e971df878da	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
54ea1cd8-62c5-4a0b-9a21-4b646c257e8a	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
4c6d85ff-f65a-4bd3-94c4-849e7edd0f7e	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
1c843ecc-afae-4a54-9b5e-5312b44cfcb3	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
28f2e20e-8f2b-4ab8-8b3d-a27bb44edd71	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
141ccd73-baa6-41e2-acfd-c34288e3b073	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
6b7536d9-769d-4075-9ddf-b61a6f028b7a	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b97d1302-2d00-4df2-81bb-c37f032fd803	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
73a624ee-63b6-46bc-91ea-5ef9cf9111bf	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
708ed5a8-ca99-4d53-b90b-444e582b48fb	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
b8e23c31-6fd4-4c30-843d-00402c89f5cb	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
427c80d0-a9a9-4198-be92-dd3f05d64395	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
25b5195a-9610-4f38-933e-3b5593e7a56a	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
f0deeeb3-4b6f-465c-811a-c34653ff9357	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
eb9ccd50-0de3-4845-81ed-ed036adef5dd	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
c5421084-6af0-41c5-a9ba-d7883168fb2d	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	5934b552-2406-4a70-b69b-f0abec6bdd28	f	\N	\N	f
2712c6f5-5eaa-4291-b5c1-6671ece24fb3	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d127a07a-15d8-47dc-9eb4-a890439b92ea	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d6a38a92-5f94-431b-9ce5-5157c7c218b1	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
c9d8c0f3-5005-4604-9821-54253129df72	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
72a21a48-2538-432b-b916-55256ef4a4f9	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
5801f820-61b5-4ef3-9d3b-f283455cd8a6	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
1616363e-4723-41c2-9385-2a7c2e57a664	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
988f41be-c3d7-4c41-b1ff-556a87eef652	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
2d58fa80-8816-440f-aa37-b388a55b1e5e	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
701170f7-82d5-4116-a47d-97c29760b41a	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
7f4930de-3daf-4e63-a7a7-e93a3bac3ede	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
3fa93e8c-3f51-4127-ac4e-d4d1f9946b4b	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d3917fe7-c757-4a97-b3d3-c7d02aa1316d	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
d4b1f2d2-cfa3-448a-a9ee-427772c84117	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
4328c865-0b25-482c-b3e1-2941573beaf4	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
f7508149-9ffe-49ac-9eed-d7da7eb4ef37	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
203ab9fe-a65a-40be-9ba7-93a201503761	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
1cd95de9-98ec-4818-afdd-826ecee36edb	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
978198b1-43bb-47ec-9102-40d6ce300411	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
b7b868ac-91cb-43f6-9150-8f628b1f2b92	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	6b39462f-1134-4e9a-9a06-f2b3687940b7	f	\N	\N	f
182dc030-cccc-4f24-af22-a9658d5aabe1	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
12a56407-2284-46ea-bfbe-fe380e342f5d	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
1d423e20-074a-4b1c-b71a-3d94301f0c2c	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
02093287-f587-4c82-9567-b0876f515f06	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
36353414-40a6-4405-be1a-9980c6b8ad63	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
28ee68de-2a39-478a-ab51-cf001c2f6202	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
5a6ce263-2603-4a5c-ae2e-b35a3c1e807b	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
a739d191-f857-4ef0-beda-891b5cc26eaa	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
2ad9f6c1-eb22-4151-8ad1-49d200eb911f	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
36aeae1c-7d36-4c35-9340-cc750795cf51	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
dc477e03-0148-4537-ade2-667d0f625b3e	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
8314200b-db00-4def-8f08-4bd6e28b85e1	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
d98ef492-4cbc-40f2-a253-cdaa6afb0d88	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
36e85b86-8fb0-4cbd-af6b-8fe49e2b7d33	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
615b2744-d70c-4cce-99e0-8bf0ebe74cb2	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
5a79f001-4ad3-43de-bea4-3453f06ee0c7	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
f3f1e538-9022-43af-896c-eff0d29aeb15	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
369450fa-7507-4599-888e-14a40d149222	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
e14a7c8b-bc4f-47f9-ad53-0e8eb1a25fbf	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
63805c2a-3560-4777-b15c-b30d0e189aa0	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	951f937f-2724-4cf5-9b4f-7528f736d782	f	\N	\N	f
9b98c62d-a70a-441b-820d-ebea9afeb0db	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
296e3d14-c53e-4935-bcc4-1f4f6285a3e4	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
24f98f22-7200-4729-a746-b0dc60949111	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
8b7c004c-0ef4-4326-9681-c6ee73db3b28	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
1344284a-af70-4354-86ed-e17a2723b2e4	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d08ad7c7-e938-40c8-a279-8987e028792a	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
5b689068-6288-4395-a081-602b84fc5fb5	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
a0b604f6-cfe5-4e8b-b8d4-51b9f62e5411	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
57f95966-4d98-4e29-8ebf-577ea80f8a91	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
19c9eade-7e89-48d0-aeac-b06e8d8e4d10	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
c20d3e81-e06a-4d83-824c-057311e17e24	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
d78740a2-d11b-4ce1-bd99-0f48a29901c6	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b5cfa414-1cf0-486d-96eb-4371869a26be	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
ee545463-8816-4e56-a859-28926201298e	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
1100b3e0-a15d-4691-bead-63ebb33f84a9	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
f77dd25b-f637-41c3-a514-9f3dab02721f	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
77778589-1be9-490e-b3f2-18294e0207f5	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
b2fd548c-2ecb-450f-9338-a84668250535	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
23c6f887-5bf8-4ab3-8288-5a1f03eae67f	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
91cd128a-f578-4c0c-8b7e-9f788c173db4	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	9fbc67a0-b671-479c-9b46-3076df068741	f	\N	\N	f
16e86001-66c7-4c4e-b537-5a3730e79110	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f46159fc-e90d-447d-a1cc-54a8d73c2138	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
439602ff-d604-4e23-a39e-7d55cd6d431c	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
b8367554-038e-47c8-914e-9911127dcbca	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
2aed3202-1ca8-47a8-856d-d6a016d60a14	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
c5d2cc44-705a-472d-8fc1-c9101bcf2821	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
444c7503-474a-4e93-9b28-ba24f6c08675	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
2c595087-f793-4b60-bd15-ffecd2759597	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
719456cb-10d0-4214-8f49-87eeee4fc7aa	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
231c57d8-0261-441b-badc-78c074a3971e	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
a7ab0124-ff13-4ecb-b990-70067cfa31d3	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
dc8a1708-ad8d-404c-a3f1-f0d39fefbeac	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
e507461f-3428-40ce-9c54-e3d28be96c3b	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
5211012a-7c47-4c6b-88d9-f8bec6620405	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
943b56b4-1938-4a4c-931f-e354f6155685	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
ef3b030e-55ee-4822-8c98-525feb64435e	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
f7a641ff-b1a4-41a4-b907-0711a950dc2d	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
35f49b10-f390-4a9c-857e-780345a3b80b	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
ebcfd77f-4443-47e4-83ad-dd33e5783846	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
8f038416-e74e-466a-bc87-e6830cc3255a	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	f	\N	\N	f
0fdf2405-bb3e-4e1a-9640-f5d1e95e59ec	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
4ba3e362-8d4f-4e1c-8274-deb0f850cc68	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a896dc03-0368-4824-abc4-6bb027c3f6e7	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
bb6aea46-359b-4695-a3e2-817a8ffb93a9	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
af8dc944-0abc-4280-9a21-3bb06f855c65	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a1b41d5b-34e0-47ca-9f1c-14e469ca780f	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
a4d38a3e-6be0-433a-9385-006ec3279847	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f922009f-1e58-496d-bf5e-4a5041750d57	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
267ce67f-e5f0-439e-867c-65da00a6b34e	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
03772728-9349-4456-b393-fc1cff831125	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
ecb6a212-a56c-4dc5-ba2a-0342b25aa06f	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
6d7517ac-74c2-4258-9fbb-eaf4e8129bd3	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
f09eb163-bf7c-4671-ab0c-fb5305454f8e	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
1904a2e9-7586-4dd0-a320-346ddcc1cc37	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
bcaf8ac6-312b-40ed-a45d-2ae036834403	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
14cec8d7-bca2-4fe0-996c-fcc46f28b52c	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
87b2893d-7877-4323-acc1-712b89deb39a	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
24027e52-f2cc-4384-b016-45bfcc3f1354	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
affc58bb-fb31-4dc9-87a8-8c3387123b62	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
eee1cefe-a3f1-4b28-ba01-965c29dc2d63	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f	\N	\N	f
fc95c4ce-5c84-4866-9801-25613ab828c3	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c7a8a789-06e5-4149-a023-54774e46906b	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
11b9066b-90e1-4539-a821-9b44c0bcc420	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a300aa83-692c-452b-a421-8ff4c41bbf7f	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
a5c7c496-d78e-418d-9900-fb7f11c32a2c	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
7aa142f5-91c2-486c-a24f-130636a1a385	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
74579dd7-7e36-44e7-9d17-cfdc6ad8efac	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
8a945433-196c-4bbe-897a-8595ef09ff2c	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
0a6348c3-e1bf-4927-8279-0067fef7c67f	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
b0cd730c-56e1-41d8-9a80-d1263a1df2c7	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
6944bddb-8e2d-4e90-8661-773733cc753f	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
c37f25db-181a-48c9-b98e-b73e668509a2	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
be74af46-bf07-43cc-b7a3-b605f6012b37	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
56d38833-de75-42c7-b29e-a1d3e8f9365b	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e16696ac-9480-41ef-a12b-77a824b8a0f4	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
e8dd9025-0691-4110-a408-b25d0bc2dd05	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
b64be34a-d231-4f74-aa34-dce6a6acc5cc	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
34d86031-1e3f-4bfd-8b4d-316138c1381e	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
ccd9bb9c-7efa-4b0e-bf02-dbc8c09e0863	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
f4de5d92-d807-4faa-8560-f46de50566b6	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	c6322771-714d-4d31-a732-47f86ac8465e	f	\N	\N	f
d803bb1d-48f8-4a1c-a4ed-ba81c97ab92d	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
fac383c1-8187-42d9-8f64-a2a1dc8f481e	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a55402c2-c98b-4f31-9f25-97227c76c97f	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
9ab1796b-7af1-4857-b71f-09754497e4df	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a1d11700-27c4-44fb-8518-c146a4a07572	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
d152903c-9bf6-411c-a76a-68334b52c62b	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
b66900ba-13b5-4731-8e36-602f76323de8	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
a7c44b71-9c98-4076-ae1a-fadfaa8d8b10	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
d4314a54-7337-4cab-8a06-d8da108c35ef	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
aa4be18b-5c4b-41f1-9296-f329a377c83d	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
5f6f76e0-67fd-4535-bd21-2362d42403a4	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
7e0d4bcb-df05-4378-b6a9-2745e4137058	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
fd1c6704-7aa9-431c-ac2a-5649de4cbb69	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
dada83fe-c8c0-4aa4-bf1e-27eadc48fe09	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c80eaa04-4e7f-4e56-9d63-61ab3d1c1418	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
dcce5e78-b534-4c95-854f-7acb426da733	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
e0e1bd7c-7c3c-42f0-b91d-101d9d0ebb4e	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
c01b3d3d-b9ff-4f24-92ad-6a668692c6db	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
6f7c4939-8a95-4767-9741-5a9284faab7a	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
bf5bc985-5d3d-4078-88f9-1e91667e7a62	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	f	\N	\N	f
99371d2c-0071-45a4-bdbd-b90003acfa33	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
e7ddb6b7-ab5c-4e1b-bedd-9d5c24041cef	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
fc8f3ef5-c8e3-49e2-b15c-cb5778191055	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
fb326a25-9b85-4cfd-9d32-225e3b9d03b0	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
823eb92f-d1de-413f-894b-addff6e39242	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
a76b8093-5aba-4018-9681-b4259868cf28	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f8513435-9fad-4452-97b1-c567904192a1	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
1dcb76d8-6ae4-4980-abd9-b5f0759f340d	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f2594b41-2fa9-488a-8650-26bd5b4a936f	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
6521302b-c478-4f4a-98e9-6e5ee5b22440	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
d201b0a8-3350-4859-8bed-89bf941fdbaa	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
c1507e1f-cfc9-4912-ae02-5d8fa12ab280	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
5553cf81-6ed4-48cc-be5c-413ee84ab8c8	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
1cdef3b9-508c-44cf-9e78-9219131cd571	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
4738f1a8-178c-4965-b71e-2759d25dc91c	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
66e0237d-38ad-4f10-8fdc-ec78b6e45f71	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
ad145d93-cdf2-4c3c-9202-59493810ea4b	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
f01f36db-2f91-4d19-bcad-1b40a2713971	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
c23e317b-63f4-4d55-b571-ca0f343ddcfe	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
9e3865a7-ef22-4d26-a4cb-a4bcd951d181	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	cf26d867-49f1-4c12-b35b-c79bfb2884fc	f	\N	\N	f
db022d1c-a339-4dd6-9178-bc8c1690deb6	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
a69c194c-2ad6-4692-88dd-530a1c434f00	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
bc5fb163-8b5d-4c36-8ad5-52e03a5f7e20	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
5379cfce-4a18-44f2-b682-b5812a609004	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
642c0003-e663-424f-a053-9e8efcd11483	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
9ea210db-826a-448d-9fa4-9f0f3ca64721	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
16e90474-6a69-478a-b5a4-0bbb9d886106	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
9676e139-c57a-43c9-80b7-1bdc9dfeb50e	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
7c4b4831-5669-45f0-845d-14a372c1b3b4	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
674dc675-0b43-468c-9356-896ab5a42892	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
fff1030a-29ad-475e-974c-cf059a981965	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
87a35a77-5dd8-4bf7-a1c6-344144b9f703	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
90d8038d-87ec-4969-ba65-4fb65a3a9c6f	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
94eb24e4-192d-4797-a0a9-3c37080c035e	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
18d3b535-fde6-44b9-b2a5-0399e555ef5e	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
9eeb7300-5354-4b16-95b7-a4d06bea2b18	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
cd7046f5-a91e-407e-a431-e202b196694a	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
14aeb97b-e7a0-4a21-828c-fa00510992f6	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
f0857d00-8a42-4e86-8abc-8529dbf98bd3	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
cf8bf15c-3ab2-4a66-9ed7-cc3d32ecddaf	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f	\N	\N	f
e59cc92b-9c8f-4d4a-a96e-c656e016dd4d	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
756f4d68-98e0-490d-8f3b-f22bb790cc60	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
2c7b16ff-1bf6-4eae-8311-0b42a42babb3	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b5b6a411-755d-42e6-bca4-566845dbe0b3	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
b0ba4224-da2d-4aed-9700-c22dc30327ac	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
2fee6d41-4feb-46cc-bfc4-1b88a22d387e	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
241d6e2b-c449-42ac-9bd3-cbe8b87be0e2	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
5c801442-91cb-4e08-9798-748599e2a37c	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
36fcf248-168b-447f-97a2-847951750fcc	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
89c35289-f805-4b23-9e59-924f9d1ed17e	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
ae283d7c-7cfe-4449-a684-5eb663600a22	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
d1e6d0e7-e59b-4c7d-ad18-ad5039d6fff4	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
d86e80a3-8d37-4374-81cd-685291dc4b87	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
adb537be-207d-47a0-b438-cde5bbbbd705	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
74facad2-a2b5-4b5a-839c-f54c0290e988	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
a019e8cd-4ab3-4318-b467-ad7caac4ee74	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
5aa8c8e7-ef26-4997-af6a-9a708318e7a0	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
c084d2e4-1795-487b-b9f1-5cb63bc45e19	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
f4739cc5-d66c-493f-9d62-6179e8c8bb5a	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
37c458ea-b619-4e86-96dc-a44b6b999537	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f	\N	\N	f
3d17fcbf-5517-4266-a8b1-467ac8374dfb	08:00:00	17:30:00	SUFFICIENT	2026-09-01	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
99cee613-14e4-4baa-8b46-e56dae3bed2d	08:00:00	17:30:00	SUFFICIENT	2026-09-02	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
56bd8f45-1f42-451a-a2a8-33a50c1bb7c0	08:35:00	17:30:00	SUFFICIENT	2026-09-03	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
da248ac3-e43f-442a-8936-9f73a4cee0dd	08:00:00	17:30:00	LATE	2026-09-04	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
6a7c94ac-fbd7-4bdc-963a-baba3082efec	08:00:00	17:30:00	SUFFICIENT	2026-09-07	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
d4373462-4d3f-44fd-87d2-97853d2f5e49	08:00:00	17:30:00	SUFFICIENT	2026-09-08	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
998707d6-6d09-4df3-a4b5-fc11dae06ab3	08:00:00	17:30:00	SUFFICIENT	2026-09-09	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
9043c65e-99ac-40a8-ba15-b744c6105a97	08:00:00	17:30:00	SUFFICIENT	2026-09-10	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
f77a15ae-96bd-4970-a033-e66913079dea	08:00:00	17:30:00	SUFFICIENT	2026-09-11	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
0105fe5f-077b-42c6-8a09-0d5a50e3a85f	08:35:00	17:30:00	SUFFICIENT	2026-09-15	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
23da2b3e-a002-474b-99b1-b35d1f06c512	08:00:00	17:30:00	SUFFICIENT	2026-09-16	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
ebe30447-55bf-493d-b1c8-eba0f72f5311	08:00:00	17:30:00	SUFFICIENT	2026-09-17	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
a6394f12-a090-4749-bd13-2fbb1dc408be	08:00:00	17:30:00	LATE	2026-09-18	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
d32f6a33-95d4-487d-b3ef-c7d89327b1b4	08:00:00	17:30:00	SUFFICIENT	2026-09-22	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
90d9d00a-8802-4f82-9917-0f632e16dcba	08:00:00	17:30:00	SUFFICIENT	2026-09-23	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
45ae55bb-25e6-454c-a443-c885b8900968	08:00:00	17:30:00	SUFFICIENT	2026-09-24	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
824ff006-703e-4f76-b43f-082b34c4cd3e	08:35:00	17:30:00	SUFFICIENT	2026-09-25	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
e28eb5f2-ecde-4ded-ac3a-f005169653e2	08:00:00	17:30:00	SUFFICIENT	2026-09-28	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
3eac11e5-bd74-460c-8b72-82862d014fcf	08:00:00	17:30:00	SUFFICIENT	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
ff995920-1a51-4c22-8ca4-141493a25dad	08:00:00	17:30:00	SUFFICIENT	2026-09-30	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	f	\N	\N	f
46d6b2c8-30c2-4b70-bc9b-66af67a78251	08:00:00	11:50:04	EARLY	2026-09-29	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	f	\N	\N	f
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
0190abcd-7000-7def-89ab-cdef0123456d	Software Engineer	0190abcd-1234-7def-89ab-cdef01234567
\.


--
-- Data for Name: leave_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.leave_requests (request_id, from_date, reason, status, approver_id, requestor_id, created_at, updated_at, to_date, paid_leave_days, rejection_reason) FROM stdin;
290d0cbe-770e-4294-880f-3afb60c0d75e	2026-07-28	Nghỉ phép năm cá nhân	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	2026-07-25 09:00:00	2026-09-29 14:28:06.973323	2026-07-28	1	\N
8ea325d9-d841-4650-be59-aed62c02352a	2026-06-12	Khám sức khỏe định kỳ	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	2026-06-09 09:00:00	2026-09-29 14:28:06.973323	2026-06-12	1	\N
ccda8e34-4723-40c3-a05a-9611d4e2d6dc	2026-03-30	Nghỉ giải quyết thủ tục hành chính	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	2026-03-27 09:00:00	2026-09-29 14:28:06.973323	2026-03-30	1	\N
c1114c8f-828d-45d1-bfd0-d9870a49deb3	2026-06-15	Việc gia đình	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	2026-06-12 09:00:00	2026-09-29 14:28:06.973323	2026-06-15	1	\N
a6ceb287-f558-4acd-ada5-8bb610aaa5c9	2026-05-15	Việc gia đình	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	2026-05-12 09:00:00	2026-09-29 14:28:06.973323	2026-05-15	1	\N
e44ff7fc-3e6d-4b78-8630-348b4741203f	2026-03-06	Khám sức khỏe định kỳ	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	2026-03-03 09:00:00	2026-09-29 14:28:06.973323	2026-03-06	1	\N
cb058910-256b-4ed3-af08-cd8d02d6e65a	2026-05-14	Khám sức khỏe định kỳ	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	2026-05-11 09:00:00	2026-09-29 14:28:06.973323	2026-05-14	1	\N
ddfc8748-628c-4874-9e79-9bad22dc6883	2026-02-09	Nghỉ phép năm cá nhân	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	2026-02-06 09:00:00	2026-09-29 14:28:06.973323	2026-02-09	1	\N
51023d11-d254-43ea-a361-f4d5d2b0e96b	2026-02-04	Nghỉ giải quyết thủ tục hành chính	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	2026-02-01 09:00:00	2026-09-29 14:28:06.973323	2026-02-04	1	\N
eb5ac2cc-3041-4c6a-a59f-29785ddeb42e	2026-08-18	Nghỉ phép năm cá nhân	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	2026-08-15 09:00:00	2026-09-29 14:28:06.973323	2026-08-18	1	\N
7011d77c-80d4-487d-a101-d44f7f264c1b	2026-05-18	Nghỉ giải quyết thủ tục hành chính	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	2026-05-15 09:00:00	2026-09-29 14:28:06.973323	2026-05-18	1	\N
49152894-b892-4f3a-80d6-501eac755f6b	2026-04-14	Nghỉ phép năm cá nhân	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	2026-04-11 09:00:00	2026-09-29 14:28:06.973323	2026-04-14	1	\N
3f72167d-4ed6-4479-8191-1a3f7c722177	2026-07-30	Việc gia đình	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	2026-07-27 09:00:00	2026-09-29 14:28:06.973323	2026-07-30	1	\N
99b355bd-564f-4b5d-bc15-dd4769b60b51	2026-05-28	Khám sức khỏe định kỳ	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	2026-05-25 09:00:00	2026-09-29 14:28:06.973323	2026-05-28	1	\N
bfd29aba-c330-4ffd-9b7f-6fb27774bcf5	2026-01-30	Khám sức khỏe định kỳ	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	2026-01-27 09:00:00	2026-09-29 14:28:06.973323	2026-01-30	1	\N
5dab8c3b-7c55-4a68-b42f-683e715ee4d8	2026-01-19	Khám sức khỏe định kỳ	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	2026-01-16 09:00:00	2026-09-29 14:28:06.973323	2026-01-19	1	\N
2f72ff5e-86e0-44de-9b11-927baa4eb13e	2026-07-28	Nghỉ phép năm cá nhân	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	2026-07-25 09:00:00	2026-09-29 14:28:06.973323	2026-07-28	1	\N
42ffd8af-56af-443d-9ca1-28ce53a6e6fc	2026-02-27	Nghỉ giải quyết thủ tục hành chính	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	2026-02-24 09:00:00	2026-09-29 14:28:06.973323	2026-02-27	1	\N
fc6d1447-6ac8-40d0-8754-e37d81ab56e6	2026-02-09	Nghỉ phép năm cá nhân	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	2026-02-06 09:00:00	2026-09-29 14:28:06.973323	2026-02-09	1	\N
2c9b2e18-e02f-46cb-a9f1-fa3e57fd1df5	2026-03-27	Việc gia đình	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	2026-03-24 09:00:00	2026-09-29 14:28:06.973323	2026-03-27	1	\N
589adf64-37de-4032-8268-7b966fd12e53	2026-02-04	Nghỉ phép năm cá nhân	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	2026-02-01 09:00:00	2026-09-29 14:28:06.973323	2026-02-04	1	\N
e53f02f5-0b81-4acb-84cf-e9ccd6ac21bf	2026-01-13	Việc gia đình	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	2026-01-10 09:00:00	2026-09-29 14:28:06.973323	2026-01-13	1	\N
b1751b23-f35a-4bc2-bf6b-6db35e1cddd5	2026-08-05	Nghỉ giải quyết thủ tục hành chính	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	2026-08-02 09:00:00	2026-09-29 14:28:06.973323	2026-08-05	1	\N
a86fe303-72d8-420d-baef-20dca0391852	2026-05-06	Nghỉ giải quyết thủ tục hành chính	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	2026-05-03 09:00:00	2026-09-29 14:28:06.973323	2026-05-06	1	\N
9968bbf9-4785-4a15-bbe0-72b62699b615	2026-03-26	Nghỉ giải quyết thủ tục hành chính	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	2026-03-23 09:00:00	2026-09-29 14:28:06.973323	2026-03-26	1	\N
f427e751-507e-4fc8-971a-98e6e00a2952	2026-04-14	Nghỉ giải quyết thủ tục hành chính	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	2026-04-11 09:00:00	2026-09-29 14:28:06.973323	2026-04-14	1	\N
ce39ba48-c443-4644-9498-d199869ad9ab	2026-03-02	Khám sức khỏe định kỳ	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	2026-02-27 09:00:00	2026-09-29 14:28:06.973323	2026-03-02	1	\N
4660524d-5905-4a3a-b92e-f5aabebb3fa9	2026-02-27	Việc gia đình	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	2026-02-24 09:00:00	2026-09-29 14:28:06.973323	2026-02-27	1	\N
7eb57efe-6594-461b-a4d0-de2e1f4440dc	2026-05-29	Việc gia đình	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	2026-05-26 09:00:00	2026-09-29 14:28:06.973323	2026-05-29	1	\N
f08923c6-db67-4909-acb8-370a00ade995	2026-04-20	Khám sức khỏe định kỳ	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	2026-04-17 09:00:00	2026-09-29 14:28:06.973323	2026-04-20	1	\N
1357625d-2408-411a-aa66-aad3d5e902f9	2026-02-06	Nghỉ giải quyết thủ tục hành chính	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	2026-02-03 09:00:00	2026-09-29 14:28:06.973323	2026-02-06	1	\N
384e61f9-30c2-4ba3-aaa3-590c264b1db4	2026-05-26	Việc gia đình	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	2026-05-23 09:00:00	2026-09-29 14:28:06.973323	2026-05-26	1	\N
106cd736-cf6c-403d-bcfc-56582490e909	2026-05-20	Nghỉ phép năm cá nhân	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	2026-05-17 09:00:00	2026-09-29 14:28:06.973323	2026-05-20	1	\N
1cf8c990-c8fe-4d15-bf27-2e7ca7f12e90	2026-03-25	Khám sức khỏe định kỳ	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	2026-03-22 09:00:00	2026-09-29 14:28:06.973323	2026-03-25	1	\N
3acb321d-b7f9-433d-9051-ff53cb2cb0ea	2026-07-23	Khám sức khỏe định kỳ	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-20 09:00:00	2026-09-29 14:28:06.973323	2026-07-23	1	\N
492efc20-e217-4ee1-ac6c-e5a5346aa354	2026-04-07	Nghỉ giải quyết thủ tục hành chính	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-04 09:00:00	2026-09-29 14:28:06.973323	2026-04-07	1	\N
6dc9a46d-7e1b-4868-b482-560203a8da74	2026-03-09	Nghỉ giải quyết thủ tục hành chính	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-06 09:00:00	2026-09-29 14:28:06.973323	2026-03-09	1	\N
5473c52f-2ddf-4702-9358-ae751011c958	2026-08-31	Việc gia đình	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2026-08-28 09:00:00	2026-09-29 14:28:06.973323	2026-08-31	1	\N
27e6d676-11b9-4549-ae78-9296daa1035b	2026-07-31	Nghỉ phép năm cá nhân	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2026-07-28 09:00:00	2026-09-29 14:28:06.973323	2026-07-31	1	\N
61be2cc8-6378-44c3-99d7-bb0a003b2e37	2026-03-30	Khám sức khỏe định kỳ	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2026-03-27 09:00:00	2026-09-29 14:28:06.973323	2026-03-30	1	\N
cc68d20c-6906-474c-8211-266043f099d5	2026-06-05	Việc gia đình	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	2026-06-02 09:00:00	2026-09-29 14:28:06.973323	2026-06-05	1	\N
2044c380-e035-4b85-a216-190d021da512	2026-05-06	Nghỉ phép năm cá nhân	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	2026-05-03 09:00:00	2026-09-29 14:28:06.973323	2026-05-06	1	\N
4f47a71f-67a5-47d6-b419-e13583d0694b	2026-01-14	Khám sức khỏe định kỳ	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	2026-01-11 09:00:00	2026-09-29 14:28:06.973323	2026-01-14	1	\N
f6b3b9f1-0916-4b65-890a-526e5e0b65fb	2026-09-16	Nghi khong luong vi ly do ca nhan	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	2026-09-27 16:54:44.256223	2026-09-29 14:28:06.973323	2026-09-16	0	\N
9400947e-5fa1-4382-9bd6-a7dce6cb9982	2026-09-14	Nghi phep nam	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	2026-09-27 16:54:44.256223	2026-09-29 14:28:06.973323	2026-09-15	2	\N
484cabe6-2307-4b12-b54f-55093bfee08d	2026-04-01	Việc gia đình	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	2026-03-29 09:00:00	2026-09-29 14:28:06.973323	2026-04-01	1	\N
ddcc79ec-5c2f-4d26-883f-c6c9602c6ea9	2026-01-27	Nghỉ phép năm cá nhân	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	2026-01-24 09:00:00	2026-09-29 14:28:06.973323	2026-01-27	1	\N
\.


--
-- Data for Name: monthly_payroll_summaries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.monthly_payroll_summaries (summary_id, period_month, period_year, total_employees, total_gross_pay, total_net_pay, total_basic_pay, total_overtime_pay, total_bonus_pay, total_allowance_pay, total_personal_income_tax, total_employee_insurance, total_company_insurance, total_union_fee, total_company_cost, status, approved_by, approved_at, created_at, updated_at) FROM stdin;
2fce279e-58aa-4d46-a08b-4be9d5676c70	1	2026	16	645526785.68	501241357.08	613000000.00	16526785.68	0.00	16000000.00	79920428.60	64365000.00	131795000.00	12260000.00	789581785.68	PAID	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-27 16:00:00+07	2026-01-26 14:00:00+07	2026-01-26 14:00:00
fefe954e-1d1f-4449-aec0-927f64321498	2	2026	16	647306250.05	503001312.54	613000000.00	18306250.05	0.00	16000000.00	79939937.51	64365000.00	131795000.00	12260000.00	791361250.05	PAID	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-27 16:00:00+07	2026-02-26 14:00:00+07	2026-02-26 14:00:00
f0c13253-74f1-4214-99da-2e53f3256e74	3	2026	16	651484375.04	506401340.93	613000000.00	14484375.04	8000000.00	16000000.00	80718034.11	64365000.00	131795000.00	12260000.00	795539375.04	PAID	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-27 16:00:00+07	2026-03-26 14:00:00+07	2026-03-26 14:00:00
7abbe5f5-904f-4224-9fd5-768e89211a4d	4	2026	16	644853125.00	500942718.77	613000000.00	15853125.00	0.00	16000000.00	79545406.23	64365000.00	131795000.00	12260000.00	788908125.00	PAID	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-27 16:00:00+07	2026-04-26 14:00:00+07	2026-04-26 14:00:00
ed4be30c-9dda-4a88-9537-ebac6b4b383b	5	2026	16	649010937.50	503563968.73	613000000.00	20010937.50	0.00	16000000.00	81081968.77	64365000.00	131795000.00	12260000.00	793065937.50	PAID	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-27 16:00:00+07	2026-05-26 14:00:00+07	2026-05-26 14:00:00
f2415123-cbcc-4091-b13c-f45664ee0795	6	2026	16	650099431.90	505567179.02	613000000.00	13099431.90	8000000.00	16000000.00	80167252.88	64365000.00	131795000.00	12260000.00	794154431.90	PAID	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-27 16:00:00+07	2026-06-26 14:00:00+07	2026-06-26 14:00:00
41aa1817-70ec-4db1-883a-098464fef1a0	7	2026	16	644754076.15	500961013.65	613000000.00	15754076.15	0.00	16000000.00	79428062.50	64365000.00	131795000.00	12260000.00	788809076.15	PAID	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-27 16:00:00+07	2026-07-26 14:00:00+07	2026-07-26 14:00:00
b795894b-b7c5-4877-855d-1512d5fa0a3e	8	2026	16	647955357.07	502959080.28	613000000.00	18955357.07	0.00	16000000.00	80631276.79	64365000.00	131795000.00	12260000.00	792010357.07	APPROVED	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-27 16:00:00+07	2026-08-26 14:00:00+07	2026-08-26 14:00:00
\.


--
-- Data for Name: monthly_timesheets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.monthly_timesheets (timesheet_id, user_id, period_month, period_year, standard_working_days, actual_worked_days, actual_work_hours, late_count, total_late_minutes, early_departure_count, absent_days, paid_leave_days, unpaid_leave_days, total_actual_ot_hours, total_paid_ot_hours, ot_details, status, note, locked_at, locked_by, created_at, updated_at) FROM stdin;
414b3276-51fd-427b-a6e1-a3e2f4220ce9	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	1	2026	21	20.00	160.00	3	45	2	0.00	1.00	0.00	3.00	4.50	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
e0929fd0-5f92-472d-8122-1bb11259b67b	5934b552-2406-4a70-b69b-f0abec6bdd28	1	2026	21	21.00	168.00	1	15	0	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
3af93799-5915-4378-8d8b-8ad90d806dae	6b39462f-1134-4e9a-9a06-f2b3687940b7	1	2026	21	20.00	160.00	0	0	0	0.00	1.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
cc01e4b4-37da-4537-a86a-6c8c56038601	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	1	2026	21	21.00	168.00	0	0	2	0.00	0.00	0.00	5.00	7.50	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
b2c88df1-bab7-40ba-a85f-74e784cbc863	c6322771-714d-4d31-a732-47f86ac8465e	1	2026	21	21.00	168.00	1	15	1	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
222d90f6-3f91-4d7e-92ce-aa0ccb2ffd74	fca9aa46-b141-415f-ab4c-9f336bdfd46e	1	2026	21	21.00	168.00	0	0	2	0.00	0.00	0.00	5.00	7.50	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
f9068774-e4c5-414f-b1b6-9d2bd7b38c10	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1	2026	21	21.00	168.00	1	15	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
3f11838b-4bbc-4b07-9b5a-5f5ae3feee87	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	1	2026	21	20.00	160.00	0	0	0	0.00	1.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
834a9b62-6eb1-491d-bdcc-dc90457a525f	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	1	2026	21	19.00	152.00	0	0	2	0.00	2.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
fecf5c28-5960-497e-a6e3-6e2c4b30b9ba	d1f7cf77-4784-4b35-8d12-f2833e3bb066	1	2026	21	21.00	168.00	0	0	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
cea03b1c-5589-484f-a060-3f30092cfc86	951f937f-2724-4cf5-9b4f-7528f736d782	1	2026	21	21.00	168.00	1	15	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
6fd70965-67d6-48dd-a903-27641ce8571f	35337165-e0d0-4dd1-9c67-cc48180363af	1	2026	21	21.00	168.00	4	60	1	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
30682aff-28d7-4a67-aac7-fb735dbbec58	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	1	2026	21	21.00	168.00	2	30	0	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
cb157d0f-4f07-4d2c-b422-8d68f4f63567	9fbc67a0-b671-479c-9b46-3076df068741	1	2026	21	20.00	160.00	2	30	1	0.00	1.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
8432f093-7825-4e66-8921-6ac931334e4c	cf26d867-49f1-4c12-b35b-c79bfb2884fc	1	2026	21	21.00	168.00	2	30	2	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
e4743ddb-8f86-44d6-b196-2b24f517dd58	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	1	2026	21	21.00	168.00	1	15	1	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-01-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-01-31 18:00:00+07	2026-01-31 18:00:00+07
bed50a0d-8934-4fed-a205-5582df36e304	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	2	2026	15	14.00	112.00	1	15	0	0.00	1.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
92d5dfbe-1e67-40a1-87c8-cfe2b3cb2fb4	5934b552-2406-4a70-b69b-f0abec6bdd28	2	2026	15	13.00	104.00	0	0	1	0.00	2.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
fa9828a1-1ce8-440c-a3b4-becbd68b15da	6b39462f-1134-4e9a-9a06-f2b3687940b7	2	2026	15	14.00	112.00	2	30	0	0.00	1.00	0.00	5.00	7.50	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
30b1eb13-9dfe-4e0d-b445-be99e7c83076	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	2	2026	15	15.00	120.00	2	30	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
4a50fcb0-d5b8-49c2-a590-6ada7e96e4c4	c6322771-714d-4d31-a732-47f86ac8465e	2	2026	15	15.00	120.00	3	45	0	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
f5004dfb-0cd6-483f-af55-928fcbe605e3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	2	2026	15	13.00	104.00	0	0	0	0.00	2.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
c9c4a0a3-f7ac-48d7-8456-1e380921b0ef	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	2	2026	15	15.00	120.00	3	45	2	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
ae2e7a3f-7ecc-4409-89f4-b8b80a51fa68	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	2	2026	15	15.00	120.00	2	30	1	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
1568903a-ebf6-48ea-abe1-0cffa2741ca3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	2	2026	15	15.00	120.00	2	30	1	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
f5e47bde-425a-4636-9485-6ac49898da6c	d1f7cf77-4784-4b35-8d12-f2833e3bb066	2	2026	15	14.00	112.00	1	15	1	0.00	1.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
be97e312-977e-4339-aec4-162f2eea99cb	951f937f-2724-4cf5-9b4f-7528f736d782	2	2026	15	15.00	120.00	3	45	2	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
e46e89b7-b81f-4219-b412-6940f06c453d	35337165-e0d0-4dd1-9c67-cc48180363af	2	2026	15	15.00	120.00	0	0	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
5f468820-7d72-44e1-bed8-e762c2a3220f	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2	2026	15	15.00	120.00	0	0	0	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
958cfb24-81f1-4718-9b12-6278acd73960	9fbc67a0-b671-479c-9b46-3076df068741	2	2026	15	15.00	120.00	0	0	1	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
08062f71-1744-4ee7-9a7b-ae31b37b489e	cf26d867-49f1-4c12-b35b-c79bfb2884fc	2	2026	15	15.00	120.00	0	0	1	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
4bb57d2d-19dc-4f55-a6cb-560e94154d0e	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	2	2026	15	14.00	112.00	0	0	0	0.00	1.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-02-28 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-02-28 18:00:00+07	2026-02-28 18:00:00+07
2d247a6f-0360-4ba3-b2ec-e707722b1b90	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	3	2026	22	22.00	176.00	1	15	3	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
e282243b-64ff-4f48-b158-c2514bf0cebf	5934b552-2406-4a70-b69b-f0abec6bdd28	3	2026	22	22.00	176.00	0	0	0	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
3e5e9812-48a8-4c7a-8ddf-84017585d4da	6b39462f-1134-4e9a-9a06-f2b3687940b7	3	2026	22	21.00	168.00	1	15	1	0.00	1.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
404b3eb6-0275-4f1b-8688-ca657013d460	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	3	2026	22	21.00	168.00	1	15	0	0.00	1.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
e72ff0df-0673-4b22-8013-2fe2258e60e5	c6322771-714d-4d31-a732-47f86ac8465e	3	2026	22	21.00	168.00	1	15	0	0.00	1.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
d81636d8-2100-45bc-b547-3f239a1050e6	fca9aa46-b141-415f-ab4c-9f336bdfd46e	3	2026	22	22.00	176.00	3	45	2	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
cd7a9a83-5669-4b9c-b62f-5f06eb8dec2d	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	3	2026	22	22.00	176.00	0	0	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
1bf758c1-477b-4f48-8730-681dfa902345	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	3	2026	22	22.00	176.00	2	30	2	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
549c3e23-ee9a-4c09-8783-b1fbd07d11a3	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	3	2026	22	22.00	176.00	3	45	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
9a4f40ef-7b68-4102-83ee-20b18965413a	d1f7cf77-4784-4b35-8d12-f2833e3bb066	3	2026	22	22.00	176.00	3	45	0	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
81ef2c00-6e2c-46b8-8fb8-ac88396039f0	951f937f-2724-4cf5-9b4f-7528f736d782	3	2026	22	21.00	168.00	3	45	3	0.00	1.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
0fc8cbb2-1fc3-4c85-beb7-2b02da1b52b9	35337165-e0d0-4dd1-9c67-cc48180363af	3	2026	22	21.00	168.00	3	45	0	0.00	1.00	0.00	3.00	4.50	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
0b1866e4-dddf-43a7-94e4-16a67d533a0c	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	3	2026	22	21.00	168.00	2	30	1	0.00	1.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
44267bef-88c7-4157-a155-9790fbdbc8f2	9fbc67a0-b671-479c-9b46-3076df068741	3	2026	22	22.00	176.00	1	15	1	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
1ae1e63e-b0d1-4c97-8574-9f3e54ecccb6	cf26d867-49f1-4c12-b35b-c79bfb2884fc	3	2026	22	21.00	168.00	0	0	0	0.00	1.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
82ce7bac-e393-47b9-947a-eddac2442351	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	3	2026	22	21.00	168.00	2	30	2	0.00	1.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-03-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-03-31 18:00:00+07	2026-03-31 18:00:00+07
7e14825a-d4a5-4743-8d81-c04fe2dc4d80	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	4	2026	20	20.00	160.00	1	15	1	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
ccce95ed-e9ca-48cd-b966-6e3a5e32f283	5934b552-2406-4a70-b69b-f0abec6bdd28	4	2026	20	20.00	160.00	1	15	0	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
8860a197-d155-4234-ad0b-1a3a311be434	6b39462f-1134-4e9a-9a06-f2b3687940b7	4	2026	20	20.00	160.00	3	45	1	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
92447907-a318-458d-856b-4c40179296c8	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	4	2026	20	20.00	160.00	0	0	2	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
3dbc6cb7-3d59-446a-b1c1-ba4118f20dca	c6322771-714d-4d31-a732-47f86ac8465e	4	2026	20	20.00	160.00	1	15	1	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
9dca3e65-34bb-438f-a3a4-408565e4b1ac	fca9aa46-b141-415f-ab4c-9f336bdfd46e	4	2026	20	20.00	160.00	2	30	0	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
d35458c3-879a-4420-95c0-1bd5a62dc584	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	4	2026	20	19.00	152.00	0	0	0	0.00	1.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
15587f7e-fbda-4625-b4c2-bc0f3fb8c7ef	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	4	2026	20	20.00	160.00	1	15	2	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
a620811f-7725-4915-adbe-12175b73a893	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	4	2026	20	19.00	152.00	0	0	0	0.00	1.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
25bcdfac-b6ac-4b51-9179-9e5fd8abde81	d1f7cf77-4784-4b35-8d12-f2833e3bb066	4	2026	20	19.00	152.00	0	0	1	0.00	1.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
79957885-16e5-4ed7-a3e5-eccacabc3063	951f937f-2724-4cf5-9b4f-7528f736d782	4	2026	20	20.00	160.00	0	0	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
9e12cd99-a773-47c8-8b08-63320dce499b	35337165-e0d0-4dd1-9c67-cc48180363af	4	2026	20	19.00	152.00	0	0	0	0.00	1.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
927997a0-e3a5-4f7f-a81c-daa1686153a3	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	4	2026	20	20.00	160.00	0	0	1	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
17b8619c-6b11-4122-844a-106f84570ab4	9fbc67a0-b671-479c-9b46-3076df068741	4	2026	20	20.00	160.00	1	15	0	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
e1867584-f9b1-4367-9865-0110fa270205	cf26d867-49f1-4c12-b35b-c79bfb2884fc	4	2026	20	20.00	160.00	1	15	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
4aec699d-b19b-4564-9092-312946a679b0	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	4	2026	20	19.00	152.00	1	15	2	0.00	1.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-04-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-04-30 18:00:00+07	2026-04-30 18:00:00+07
2ce69ae0-a1c8-4903-82b4-925a99f3ae1f	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5	2026	20	20.00	160.00	0	0	0	0.00	0.00	0.00	5.00	7.50	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
7d85199f-5e2c-4eaf-9acc-8625923f9c13	5934b552-2406-4a70-b69b-f0abec6bdd28	5	2026	20	20.00	160.00	1	15	0	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
147ad841-bdc6-4166-aecc-57e6d84e9335	6b39462f-1134-4e9a-9a06-f2b3687940b7	5	2026	20	20.00	160.00	1	15	1	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
b31f33f3-68a5-4189-a1ad-2b88d6f6d8b6	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	5	2026	20	20.00	160.00	0	0	0	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
96d125bf-811e-4a6f-9a15-3031907520fe	c6322771-714d-4d31-a732-47f86ac8465e	5	2026	20	19.00	152.00	0	0	0	0.00	1.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
1a6aff5b-c02c-4ffe-b437-2dc2547c3699	fca9aa46-b141-415f-ab4c-9f336bdfd46e	5	2026	20	19.00	152.00	2	30	0	0.00	1.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
d85090c3-8277-4a25-94d3-984e334f4c98	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	5	2026	20	19.00	152.00	1	15	1	0.00	1.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
7c5f68e1-61f5-498f-b041-d14e0fe7fdb5	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	5	2026	20	19.00	152.00	2	30	2	0.00	1.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
03bc2a32-fc90-48a4-978a-2ecbd712d887	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	5	2026	20	20.00	160.00	1	15	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
081e0396-083b-45a7-b4d9-c6a97b5f945e	d1f7cf77-4784-4b35-8d12-f2833e3bb066	5	2026	20	19.00	152.00	3	45	3	0.00	1.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
2f97d967-75aa-4168-961d-13860ba13d6b	951f937f-2724-4cf5-9b4f-7528f736d782	5	2026	20	18.00	144.00	0	0	1	0.00	2.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
1d52d2ea-9f79-4280-b946-0a10780d9701	35337165-e0d0-4dd1-9c67-cc48180363af	5	2026	20	20.00	160.00	2	30	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
b4570934-2886-4995-9271-cf72b4604963	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	5	2026	20	20.00	160.00	0	0	0	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
fd03caa1-e4c7-49a3-92c7-e0c7e248b173	9fbc67a0-b671-479c-9b46-3076df068741	5	2026	20	19.00	152.00	1	15	0	0.00	1.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
353a814e-def1-472d-9a06-2d83b08e9ad7	cf26d867-49f1-4c12-b35b-c79bfb2884fc	5	2026	20	19.00	152.00	0	0	0	0.00	1.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
75309f98-65fe-4a05-99e2-63fd232fecb7	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	5	2026	20	20.00	160.00	2	30	1	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-05-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-05-31 18:00:00+07	2026-05-31 18:00:00+07
6c38445a-2a53-4c99-b81f-ad3898e69869	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	6	2026	22	22.00	176.00	1	15	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
b283af7a-bdb8-4919-b91e-4ea42e8f5f49	5934b552-2406-4a70-b69b-f0abec6bdd28	6	2026	22	22.00	176.00	1	15	2	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
b5a9bcd1-2617-458c-b26e-b3edde9ac78a	6b39462f-1134-4e9a-9a06-f2b3687940b7	6	2026	22	22.00	176.00	1	15	0	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
d65ceb69-96ea-4793-9a17-32946ee38b1f	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	6	2026	22	21.00	168.00	1	15	0	0.00	1.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
393f3883-dee2-4ee4-aa5b-92d963c605b3	c6322771-714d-4d31-a732-47f86ac8465e	6	2026	22	21.00	168.00	3	45	1	0.00	1.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
0b9f1080-99aa-4fb4-9ddc-0dd7122d7757	fca9aa46-b141-415f-ab4c-9f336bdfd46e	6	2026	22	22.00	176.00	1	15	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
bc0a33af-89c0-4d97-82d3-b68cbe8f9905	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	6	2026	22	22.00	176.00	1	15	0	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
edcd9150-40c2-4959-96d6-eed41e939bb7	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	6	2026	22	22.00	176.00	1	15	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
48b41ca4-65ec-4d7e-8b09-1ce4ca89f303	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	6	2026	22	22.00	176.00	1	15	1	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
d434e92a-1e10-4cd7-a0ba-9de7eb923a86	d1f7cf77-4784-4b35-8d12-f2833e3bb066	6	2026	22	22.00	176.00	1	15	2	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
628e25c8-8d51-4e98-8b22-3fad1526745b	951f937f-2724-4cf5-9b4f-7528f736d782	6	2026	22	22.00	176.00	0	0	1	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
ef7b3ee1-5404-467d-940a-dd0a312dc25d	35337165-e0d0-4dd1-9c67-cc48180363af	6	2026	22	22.00	176.00	1	15	0	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
1322956c-10b8-44e1-985c-5fec39a8bfe8	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	6	2026	22	22.00	176.00	3	45	3	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
40b21b60-9978-4c33-a420-bf3a775a532d	9fbc67a0-b671-479c-9b46-3076df068741	6	2026	22	21.00	168.00	5	75	1	0.00	1.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
e800819a-800e-46fc-b1c0-ab332ea5b20c	cf26d867-49f1-4c12-b35b-c79bfb2884fc	6	2026	22	22.00	176.00	0	0	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
2f2bbc9c-c4e9-471b-acb5-43e11f7c7b7a	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	6	2026	22	22.00	176.00	1	15	0	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-06-30 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-06-30 18:00:00+07	2026-06-30 18:00:00+07
305fbfd7-0624-4299-891e-112f1ed7f97e	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	7	2026	23	23.00	184.00	1	15	1	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
0a28674e-8667-44c5-b065-7b00b1159ec4	5934b552-2406-4a70-b69b-f0abec6bdd28	7	2026	23	22.00	176.00	3	45	0	0.00	1.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
77b0d151-bfa1-49cb-9014-96ed10db4e6b	6b39462f-1134-4e9a-9a06-f2b3687940b7	7	2026	23	23.00	184.00	0	0	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
3214f4c6-b903-431b-8908-e6f3a1884d15	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	7	2026	23	22.00	176.00	0	0	1	0.00	1.00	0.00	3.00	4.50	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
197d78f0-5b9e-4409-98af-9a4b7b4ba71a	c6322771-714d-4d31-a732-47f86ac8465e	7	2026	23	23.00	184.00	3	45	3	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
c8233dbf-910a-414a-8be3-b4595003602b	fca9aa46-b141-415f-ab4c-9f336bdfd46e	7	2026	23	23.00	184.00	1	15	1	0.00	0.00	0.00	3.00	4.50	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
f7abe3e5-3289-4aee-90a0-d61ce26742b2	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	7	2026	23	23.00	184.00	2	30	0	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
3d9f34be-c6fe-4017-910f-05e73aba6276	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	7	2026	23	22.00	176.00	0	0	0	0.00	1.00	0.00	5.00	7.50	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
5d23ac7f-0bf2-4bad-843e-a59acb5e3bcf	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	7	2026	23	23.00	184.00	1	15	0	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
42112cc7-4b33-4c7b-ac90-cb852fa6d8d0	d1f7cf77-4784-4b35-8d12-f2833e3bb066	7	2026	23	23.00	184.00	2	30	2	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
c95bdd4d-05c1-4b11-91e8-b3bcf62a0373	951f937f-2724-4cf5-9b4f-7528f736d782	7	2026	23	23.00	184.00	1	15	0	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
28a837e9-9668-4279-8caf-719c5c6c4394	35337165-e0d0-4dd1-9c67-cc48180363af	7	2026	23	22.00	176.00	2	30	1	0.00	1.00	0.00	5.00	7.50	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
95c56641-7a4e-46f5-82b4-2eb8a0f3d3d6	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	7	2026	23	22.00	176.00	1	15	0	0.00	1.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
53180f72-29fa-4b7a-91ef-ff91222501f5	9fbc67a0-b671-479c-9b46-3076df068741	7	2026	23	23.00	184.00	1	15	0	0.00	0.00	0.00	5.00	7.50	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
3c1b434e-18ba-4f67-aa8b-d1cb592b6d77	cf26d867-49f1-4c12-b35b-c79bfb2884fc	7	2026	23	23.00	184.00	3	45	1	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
d19fc0bb-b898-435d-b07c-2418f6c23101	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	7	2026	23	23.00	184.00	0	0	1	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-07-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-07-31 18:00:00+07	2026-07-31 18:00:00+07
1f0636e9-1a9d-49a5-a08d-4d020197cea0	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	8	2026	21	20.00	160.00	2	30	1	0.00	1.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
d3f45f93-30b0-408b-881e-38c8f87c451e	5934b552-2406-4a70-b69b-f0abec6bdd28	8	2026	21	21.00	168.00	2	30	2	0.00	0.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
f7198862-c381-40fe-b5e9-eb6b2f4b2caf	6b39462f-1134-4e9a-9a06-f2b3687940b7	8	2026	21	21.00	168.00	2	30	1	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
bb999c00-ed3e-4720-a575-c5810283673d	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	8	2026	21	21.00	168.00	3	45	1	0.00	0.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
c025be56-fa67-44fa-9818-d07c34e5f309	c6322771-714d-4d31-a732-47f86ac8465e	8	2026	21	21.00	168.00	2	30	1	0.00	0.00	0.00	3.00	4.50	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
99916a4f-6937-4575-a4a5-6bf6ff7d8e8f	fca9aa46-b141-415f-ab4c-9f336bdfd46e	8	2026	21	21.00	168.00	1	15	1	0.00	0.00	0.00	5.00	7.50	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
044d98cf-b2e4-4aa3-9c1c-6b3545076d1b	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	8	2026	21	20.00	160.00	1	15	2	0.00	1.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
47e82509-e8bd-452b-8430-0ae6e6bd0b41	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	8	2026	21	21.00	168.00	2	30	0	0.00	0.00	0.00	3.50	5.25	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
7e39afba-27d4-4bf4-99ec-f6f8f7f229dd	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	8	2026	21	21.00	168.00	2	30	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
aea49108-8198-40ae-b664-5f9a67df5283	d1f7cf77-4784-4b35-8d12-f2833e3bb066	8	2026	21	21.00	168.00	1	15	0	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
ed4f48d2-6d7a-4915-a3fa-cadd3eeb545a	951f937f-2724-4cf5-9b4f-7528f736d782	8	2026	21	21.00	168.00	4	60	1	0.00	0.00	0.00	1.50	2.25	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
81819ef1-4b59-43e5-b818-3d176425398b	35337165-e0d0-4dd1-9c67-cc48180363af	8	2026	21	21.00	168.00	0	0	2	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
480689f8-1d1f-4ce4-b470-ff152361e8bc	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	8	2026	21	20.00	160.00	2	30	0	0.00	1.00	0.00	4.50	6.75	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
d76e7b81-9d73-4be6-9523-7b984b8fe98b	9fbc67a0-b671-479c-9b46-3076df068741	8	2026	21	21.00	168.00	2	30	1	0.00	0.00	0.00	2.50	3.75	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
802e06d2-b7ab-4e36-abcd-084cc3b73e7f	cf26d867-49f1-4c12-b35b-c79bfb2884fc	8	2026	21	20.00	160.00	2	30	2	0.00	1.00	0.00	4.00	6.00	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
2153268e-2510-471b-afc5-d86f7362af1a	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	8	2026	21	21.00	168.00	0	0	0	0.00	0.00	0.00	2.00	3.00	\N	LOCKED	\N	2026-08-31 18:00:00+07	35337165-e0d0-4dd1-9c67-cc48180363af	2026-08-31 18:00:00+07	2026-08-31 18:00:00+07
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
a9708202-e995-49a6-ac03-ce70319bcdb3	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hoan thanh bao cao tai chinh	\N
c4bfd949-2b69-4323-b3f5-871f9dda2c74	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hoan thanh giao hang cuoi thang	\N
e6bf1612-e36a-4e96-b266-08a8157ee167	2026-08-11	2026-08-11 20:30:00	2026-08-11 18:00:00	2026-08-11 18:00:00	2026-08-11 20:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bàn giao dự án	\N
ada01fe6-284e-40b5-b112-2b89cea0a9e6	2026-08-06	2026-08-06 19:30:00	2026-08-06 18:00:00	2026-08-06 18:00:00	2026-08-06 19:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Xử lý sự cố hạ tầng	\N
ddfb7ef5-0824-4930-a995-2c770b7263ad	2026-07-03	2026-07-03 20:00:00	2026-07-03 18:00:00	2026-07-03 18:00:00	2026-07-03 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Xử lý sự cố hạ tầng	\N
e43c974b-44cc-4d9d-b4c7-965b63c3985b	2026-07-01	2026-07-01 20:00:00	2026-07-01 18:00:00	2026-07-01 18:00:00	2026-07-01 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Xử lý sự cố hạ tầng	\N
2925c47f-430d-46ba-bbc6-70aec0f60eab	2026-06-26	2026-06-26 19:30:00	2026-06-26 18:00:00	2026-06-26 18:00:00	2026-06-26 19:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Xử lý sự cố hạ tầng	\N
a2bc4802-b33a-4828-bd1c-882671dba600	2026-05-25	2026-05-25 19:30:00	2026-05-25 18:00:00	2026-05-25 18:00:00	2026-05-25 19:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hoàn tất báo cáo định kỳ	\N
2d40f2e3-a153-4d7a-8ed4-7b48bae77f04	2026-05-11	2026-05-11 20:00:00	2026-05-11 18:00:00	2026-05-11 18:00:00	2026-05-11 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hoàn tất báo cáo định kỳ	\N
318a46e3-c9e4-4029-81cd-2b4ac618c019	2026-04-30	2026-04-30 20:00:00	2026-04-30 18:00:00	2026-04-30 18:00:00	2026-04-30 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hoàn tất báo cáo định kỳ	\N
ee67e995-9509-46df-ac78-d65b9def8be7	2026-03-20	2026-03-20 20:30:00	2026-03-20 18:00:00	2026-03-20 18:00:00	2026-03-20 20:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Tối ưu hóa dữ liệu khách hàng	\N
05e0adc9-9a31-4b92-ad48-1a65ddf0b8f0	2026-02-10	2026-02-10 20:00:00	2026-02-10 18:00:00	2026-02-10 18:00:00	2026-02-10 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Xử lý sự cố hạ tầng	\N
78a23f91-dc66-4faa-a594-ee5be8f4009c	2026-01-05	2026-01-05 20:00:00	2026-01-05 18:00:00	2026-01-05 18:00:00	2026-01-05 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	cf26d867-49f1-4c12-b35b-c79bfb2884fc	Hỗ trợ bàn giao dự án	\N
a4b47a87-a62b-424a-82fd-57ebdd3f2e7f	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Hoan thanh bao cao tai chinh	\N
f665f377-56f8-42d1-b897-10d89838fedd	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Hoan thanh giao hang cuoi thang	\N
6ec2506b-7db5-4d13-8947-946e0e6c0153	2026-08-03	2026-08-03 20:00:00	2026-08-03 18:00:00	2026-08-03 18:00:00	2026-08-03 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Tối ưu hóa dữ liệu khách hàng	\N
ca365776-5992-4102-af8b-c620b9e90e35	2026-07-27	2026-07-27 20:30:00	2026-07-27 18:00:00	2026-07-27 18:00:00	2026-07-27 20:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Hoàn tất báo cáo định kỳ	\N
3360135b-dc68-4f51-9fa9-eed3f973e9f7	2026-07-30	2026-07-30 20:00:00	2026-07-30 18:00:00	2026-07-30 18:00:00	2026-07-30 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Tối ưu hóa dữ liệu khách hàng	\N
5112f9d8-017f-4e4c-a2cd-8b51225d15f7	2026-06-22	2026-06-22 20:30:00	2026-06-22 18:00:00	2026-06-22 18:00:00	2026-06-22 20:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Hỗ trợ bàn giao dự án	\N
ff584eed-0883-4177-82dc-ca0c03417a4a	2026-05-12	2026-05-12 19:30:00	2026-05-12 18:00:00	2026-05-12 18:00:00	2026-05-12 19:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Hoàn tất báo cáo định kỳ	\N
1816abb1-25e9-4497-8ece-4a1844b4e4d8	2026-05-29	2026-05-29 20:00:00	2026-05-29 18:00:00	2026-05-29 18:00:00	2026-05-29 20:00:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Tối ưu hóa dữ liệu khách hàng	\N
1260ed5d-f71e-4245-92f0-5846d3bdfdf9	2026-04-15	2026-04-15 20:30:00	2026-04-15 18:00:00	2026-04-15 18:00:00	2026-04-15 20:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Hoàn tất báo cáo định kỳ	\N
c0202347-9bd1-477e-8ca4-110844be56dd	2026-03-06	2026-03-06 19:30:00	2026-03-06 18:00:00	2026-03-06 18:00:00	2026-03-06 19:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Xử lý sự cố hạ tầng	\N
6d3b8169-bafc-46b1-af64-5886ad036522	2026-02-26	2026-02-26 20:30:00	2026-02-26 18:00:00	2026-02-26 18:00:00	2026-02-26 20:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Hỗ trợ bàn giao dự án	\N
329c4110-dd07-4bd4-b9a9-3e3d088e7b1c	2026-01-27	2026-01-27 19:30:00	2026-01-27 18:00:00	2026-01-27 18:00:00	2026-01-27 19:30:00	f	f	f	accepted	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	Hỗ trợ bàn giao dự án	\N
b0be776f-2214-410e-9a9f-60613459baa5	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hoan thanh bao cao tai chinh	\N
060945ec-46a3-4d7a-bb48-cbaf7d4ad993	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hoan thanh giao hang cuoi thang	\N
f8196938-9f76-4058-b8cf-5b80a82e8ae4	2026-08-07	2026-08-07 19:30:00	2026-08-07 18:00:00	2026-08-07 18:00:00	2026-08-07 19:30:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hoàn tất báo cáo định kỳ	\N
1f427208-cfea-4914-84bc-660fb6bd94d4	2026-07-10	2026-07-10 20:00:00	2026-07-10 18:00:00	2026-07-10 18:00:00	2026-07-10 20:00:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bàn giao dự án	\N
e61ec5d9-5530-4236-bb56-c56ae773781e	2026-07-21	2026-07-21 20:00:00	2026-07-21 18:00:00	2026-07-21 18:00:00	2026-07-21 20:00:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Tối ưu hóa dữ liệu khách hàng	\N
db2e73d4-99bc-4af3-8a67-beebed520d5b	2026-06-19	2026-06-19 19:30:00	2026-06-19 18:00:00	2026-06-19 18:00:00	2026-06-19 19:30:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bàn giao dự án	\N
3142f934-8b37-4a3d-ba8b-6e4e6aff3186	2026-05-27	2026-05-27 20:00:00	2026-05-27 18:00:00	2026-05-27 18:00:00	2026-05-27 20:00:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Tối ưu hóa dữ liệu khách hàng	\N
21ed5c43-e8b7-4cad-bd94-e86ee5eff701	2026-05-20	2026-05-20 19:30:00	2026-05-20 18:00:00	2026-05-20 18:00:00	2026-05-20 19:30:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Tối ưu hóa dữ liệu khách hàng	\N
52b2fa05-92c6-4ed7-957f-039920dd07f7	2026-04-13	2026-04-13 20:30:00	2026-04-13 18:00:00	2026-04-13 18:00:00	2026-04-13 20:30:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hoàn tất báo cáo định kỳ	\N
19eda3a7-ad53-4f6b-a828-b25d97e2e675	2026-04-03	2026-04-03 20:00:00	2026-04-03 18:00:00	2026-04-03 18:00:00	2026-04-03 20:00:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Tối ưu hóa dữ liệu khách hàng	\N
fdea4477-61b7-4dd3-a9ca-d9984d08f238	2026-03-09	2026-03-09 20:30:00	2026-03-09 18:00:00	2026-03-09 18:00:00	2026-03-09 20:30:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bàn giao dự án	\N
427ada8c-e883-4a41-90f8-e974153c60e6	2026-03-13	2026-03-13 20:00:00	2026-03-13 18:00:00	2026-03-13 18:00:00	2026-03-13 20:00:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hoàn tất báo cáo định kỳ	\N
c6a15e75-5237-4c79-ac62-08ca9772fad0	2026-02-23	2026-02-23 20:30:00	2026-02-23 18:00:00	2026-02-23 18:00:00	2026-02-23 20:30:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bàn giao dự án	\N
785a6edf-43e2-47fe-bae1-0a58b12d9e0c	2026-01-02	2026-01-02 19:30:00	2026-01-02 18:00:00	2026-01-02 18:00:00	2026-01-02 19:30:00	f	f	f	accepted	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d1f7cf77-4784-4b35-8d12-f2833e3bb066	Hỗ trợ bàn giao dự án	\N
bc191568-3575-488b-b001-e4cecb5a4c4c	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Hoan thanh bao cao tai chinh	\N
af4dab48-d4d4-44bb-b7c8-24a176c0526e	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Hoan thanh giao hang cuoi thang	\N
78f8b0ac-b70a-435f-9b25-f32dcbf53ae2	2026-08-12	2026-08-12 19:30:00	2026-08-12 18:00:00	2026-08-12 18:00:00	2026-08-12 19:30:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Tối ưu hóa dữ liệu khách hàng	\N
dd49f1e7-f82b-48de-ae19-83fb1ae6769d	2026-07-08	2026-07-08 20:00:00	2026-07-08 18:00:00	2026-07-08 18:00:00	2026-07-08 20:00:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Hoàn tất báo cáo định kỳ	\N
48e4b66f-f702-467d-9274-0e7d896dca70	2026-07-15	2026-07-15 20:00:00	2026-07-15 18:00:00	2026-07-15 18:00:00	2026-07-15 20:00:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Xử lý sự cố hạ tầng	\N
d98acbae-0f31-455b-a665-89ff5401a880	2026-06-15	2026-06-15 20:00:00	2026-06-15 18:00:00	2026-06-15 18:00:00	2026-06-15 20:00:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Hoàn tất báo cáo định kỳ	\N
272db5f0-ce78-49a8-8fc6-6e765e664cff	2026-06-17	2026-06-17 19:30:00	2026-06-17 18:00:00	2026-06-17 18:00:00	2026-06-17 19:30:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Tối ưu hóa dữ liệu khách hàng	\N
05fdc622-eff9-43f4-a51a-7c67ab3ce721	2026-05-07	2026-05-07 20:30:00	2026-05-07 18:00:00	2026-05-07 18:00:00	2026-05-07 20:30:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bàn giao dự án	\N
5d9fe36d-e892-43a7-93b5-232ab6be2df6	2026-04-06	2026-04-06 20:00:00	2026-04-06 18:00:00	2026-04-06 18:00:00	2026-04-06 20:00:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Xử lý sự cố hạ tầng	\N
cff1e699-8b27-45aa-a2da-ddd859ecf5a5	2026-03-06	2026-03-06 19:30:00	2026-03-06 18:00:00	2026-03-06 18:00:00	2026-03-06 19:30:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Xử lý sự cố hạ tầng	\N
6cfe5e57-4d55-4ae1-85df-ec7208120203	2026-03-05	2026-03-05 20:00:00	2026-03-05 18:00:00	2026-03-05 18:00:00	2026-03-05 20:00:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bàn giao dự án	\N
8d572ae8-32f5-4d3a-a703-b630ab9ae682	2026-02-25	2026-02-25 19:30:00	2026-02-25 18:00:00	2026-02-25 18:00:00	2026-02-25 19:30:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Hỗ trợ bàn giao dự án	\N
55ebbe3f-4684-4e1a-986b-d3026e2b4f71	2026-01-22	2026-01-22 19:30:00	2026-01-22 18:00:00	2026-01-22 18:00:00	2026-01-22 19:30:00	f	f	f	accepted	c6322771-714d-4d31-a732-47f86ac8465e	951f937f-2724-4cf5-9b4f-7528f736d782	Xử lý sự cố hạ tầng	\N
fa7e8d2b-c07e-451d-ba23-3815dd1728d5	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hoan thanh bao cao tai chinh	\N
f5369123-34b6-4dd8-ad96-c4eb5fcb0a84	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hoan thanh giao hang cuoi thang	\N
c64117bd-4d07-4ed4-a666-8f8076462104	2026-08-25	2026-08-25 20:00:00	2026-08-25 18:00:00	2026-08-25 18:00:00	2026-08-25 20:00:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Tối ưu hóa dữ liệu khách hàng	\N
f7d813c1-a4ee-475f-8a89-6c382f88986f	2026-07-29	2026-07-29 20:30:00	2026-07-29 18:00:00	2026-07-29 18:00:00	2026-07-29 20:30:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bàn giao dự án	\N
25780621-30d7-4161-89bc-7409d5fd95d3	2026-07-13	2026-07-13 20:30:00	2026-07-13 18:00:00	2026-07-13 18:00:00	2026-07-13 20:30:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hoàn tất báo cáo định kỳ	\N
fc944490-e647-4203-b5ab-c889264dcf79	2026-06-18	2026-06-18 20:00:00	2026-06-18 18:00:00	2026-06-18 18:00:00	2026-06-18 20:00:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bàn giao dự án	\N
4b516fb6-4014-4449-84d6-e3f9cb9619c8	2026-06-11	2026-06-11 20:00:00	2026-06-11 18:00:00	2026-06-11 18:00:00	2026-06-11 20:00:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hỗ trợ bàn giao dự án	\N
86e81bde-b276-4021-8bcd-ad52b5a69f77	2026-05-20	2026-05-20 19:30:00	2026-05-20 18:00:00	2026-05-20 18:00:00	2026-05-20 19:30:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Xử lý sự cố hạ tầng	\N
e59c6809-fe6a-4dc0-baf2-20d51bd84375	2026-04-06	2026-04-06 20:00:00	2026-04-06 18:00:00	2026-04-06 18:00:00	2026-04-06 20:00:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hoàn tất báo cáo định kỳ	\N
37fe73f8-4225-4688-930a-1b16a00e4417	2026-04-02	2026-04-02 20:30:00	2026-04-02 18:00:00	2026-04-02 18:00:00	2026-04-02 20:30:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Tối ưu hóa dữ liệu khách hàng	\N
03b00a14-bc91-4eaa-9a09-f43ab27204ff	2026-03-30	2026-03-30 19:30:00	2026-03-30 18:00:00	2026-03-30 18:00:00	2026-03-30 19:30:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hoàn tất báo cáo định kỳ	\N
f947ba28-be5f-432e-999f-d90ad5e8d2d4	2026-03-16	2026-03-16 19:30:00	2026-03-16 18:00:00	2026-03-16 18:00:00	2026-03-16 19:30:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Hoàn tất báo cáo định kỳ	\N
c15b6d48-ac7c-4b9b-bee2-c796e7e197fe	2026-02-09	2026-02-09 20:00:00	2026-02-09 18:00:00	2026-02-09 18:00:00	2026-02-09 20:00:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Tối ưu hóa dữ liệu khách hàng	\N
17c03836-b32f-453f-aefa-f3ffd62708b8	2026-01-30	2026-01-30 20:00:00	2026-01-30 18:00:00	2026-01-30 18:00:00	2026-01-30 20:00:00	f	f	f	accepted	fca9aa46-b141-415f-ab4c-9f336bdfd46e	35337165-e0d0-4dd1-9c67-cc48180363af	Xử lý sự cố hạ tầng	\N
f6985f73-452f-4705-b338-d365edad6741	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hoan thanh bao cao tai chinh	\N
0148743d-96f0-403d-bccd-ff2318258df8	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hoan thanh giao hang cuoi thang	\N
985073bf-8594-4135-8c67-2366ac792d16	2026-08-27	2026-08-27 20:30:00	2026-08-27 18:00:00	2026-08-27 18:00:00	2026-08-27 20:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bàn giao dự án	\N
725715e8-eb67-4916-a967-88edca970382	2026-08-14	2026-08-14 20:00:00	2026-08-14 18:00:00	2026-08-14 18:00:00	2026-08-14 20:00:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hoàn tất báo cáo định kỳ	\N
dd91c111-4a99-41b7-bd24-1f7cfee14e90	2026-07-03	2026-07-03 19:30:00	2026-07-03 18:00:00	2026-07-03 18:00:00	2026-07-03 19:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Tối ưu hóa dữ liệu khách hàng	\N
a0fd05d9-60b5-4d7b-a338-04918c1b3a02	2026-06-16	2026-06-16 19:30:00	2026-06-16 18:00:00	2026-06-16 18:00:00	2026-06-16 19:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bàn giao dự án	\N
275ef6e1-ea9c-4ba5-9a5f-3e6af681a79a	2026-05-26	2026-05-26 20:00:00	2026-05-26 18:00:00	2026-05-26 18:00:00	2026-05-26 20:00:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Xử lý sự cố hạ tầng	\N
132a38c6-2589-4ee8-bd6c-93962fbdb151	2026-05-04	2026-05-04 19:30:00	2026-05-04 18:00:00	2026-05-04 18:00:00	2026-05-04 19:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bàn giao dự án	\N
693b5dd6-99f1-4d0f-a86b-43b8bdd992c8	2026-04-23	2026-04-23 20:30:00	2026-04-23 18:00:00	2026-04-23 18:00:00	2026-04-23 20:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Xử lý sự cố hạ tầng	\N
1fb3297c-96c9-4ded-990c-c4c9ea7ec777	2026-04-28	2026-04-28 19:30:00	2026-04-28 18:00:00	2026-04-28 18:00:00	2026-04-28 19:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Tối ưu hóa dữ liệu khách hàng	\N
fdf4346c-567f-4e97-88bd-32877f782e92	2026-03-03	2026-03-03 20:00:00	2026-03-03 18:00:00	2026-03-03 18:00:00	2026-03-03 20:00:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bàn giao dự án	\N
ec79a81e-5b01-4293-b7c1-de86aa04e739	2026-03-12	2026-03-12 19:30:00	2026-03-12 18:00:00	2026-03-12 18:00:00	2026-03-12 19:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Tối ưu hóa dữ liệu khách hàng	\N
814a04c3-2ea8-40c4-97bc-93bf319cb89f	2026-02-18	2026-02-18 20:00:00	2026-02-18 18:00:00	2026-02-18 18:00:00	2026-02-18 20:00:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Hỗ trợ bàn giao dự án	\N
beccab99-0055-401d-a454-e5a69bdc249c	2026-02-10	2026-02-10 19:30:00	2026-02-10 18:00:00	2026-02-10 18:00:00	2026-02-10 19:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Xử lý sự cố hạ tầng	\N
fa22507a-cad5-432d-9570-0d271168c0b8	2026-01-28	2026-01-28 20:30:00	2026-01-28 18:00:00	2026-01-28 18:00:00	2026-01-28 20:30:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Xử lý sự cố hạ tầng	\N
b4627e70-74bc-4dae-82a8-2b3a243b016b	2026-01-23	2026-01-23 20:00:00	2026-01-23 18:00:00	2026-01-23 18:00:00	2026-01-23 20:00:00	f	f	f	accepted	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	Xử lý sự cố hạ tầng	\N
e5e6b057-6e3f-4196-a058-7a847aaad236	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Hoan thanh bao cao tai chinh	\N
23f61572-9f57-4d19-b2ee-a505956e7a99	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Hoan thanh giao hang cuoi thang	\N
10fbe13c-5aed-4227-abff-04afb10e32b7	2026-08-11	2026-08-11 20:30:00	2026-08-11 18:00:00	2026-08-11 18:00:00	2026-08-11 20:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố hạ tầng	\N
eb7e90ca-d36d-41e3-8786-d62432021723	2026-07-10	2026-07-10 20:30:00	2026-07-10 18:00:00	2026-07-10 18:00:00	2026-07-10 20:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Tối ưu hóa dữ liệu khách hàng	\N
434e5fc9-9341-42e2-a5c0-dd11ea32da18	2026-07-24	2026-07-24 20:30:00	2026-07-24 18:00:00	2026-07-24 18:00:00	2026-07-24 20:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Tối ưu hóa dữ liệu khách hàng	\N
d9a8a06e-1259-45ff-8d2b-f75eff49542e	2026-06-01	2026-06-01 19:30:00	2026-06-01 18:00:00	2026-06-01 18:00:00	2026-06-01 19:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố hạ tầng	\N
cffc1aac-9817-4ad3-8d60-0fbf238bd0a5	2026-05-27	2026-05-27 20:00:00	2026-05-27 18:00:00	2026-05-27 18:00:00	2026-05-27 20:00:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Tối ưu hóa dữ liệu khách hàng	\N
d53608b7-cd67-43e0-baa3-ec3bf4b5ee4d	2026-05-26	2026-05-26 20:30:00	2026-05-26 18:00:00	2026-05-26 18:00:00	2026-05-26 20:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Hoàn tất báo cáo định kỳ	\N
a91f4e9d-fc51-4beb-9c12-30736263a9c0	2026-04-20	2026-04-20 20:00:00	2026-04-20 18:00:00	2026-04-20 18:00:00	2026-04-20 20:00:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Tối ưu hóa dữ liệu khách hàng	\N
9e164064-4950-47b5-8b51-fa75974ea537	2026-04-02	2026-04-02 19:30:00	2026-04-02 18:00:00	2026-04-02 18:00:00	2026-04-02 19:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố hạ tầng	\N
ee3565b0-7f2c-4d35-991a-f7391b042cf7	2026-03-16	2026-03-16 19:30:00	2026-03-16 18:00:00	2026-03-16 18:00:00	2026-03-16 19:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Hoàn tất báo cáo định kỳ	\N
454b8a69-3cd1-4d58-ae76-321051a35f85	2026-02-20	2026-02-20 20:30:00	2026-02-20 18:00:00	2026-02-20 18:00:00	2026-02-20 20:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Tối ưu hóa dữ liệu khách hàng	\N
398e7610-6076-46bc-bbab-643612dfffca	2026-02-12	2026-02-12 20:00:00	2026-02-12 18:00:00	2026-02-12 18:00:00	2026-02-12 20:00:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Tối ưu hóa dữ liệu khách hàng	\N
c2712ba4-54f2-46ba-893b-7591d32583dd	2026-01-19	2026-01-19 19:30:00	2026-01-19 18:00:00	2026-01-19 18:00:00	2026-01-19 19:30:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Xử lý sự cố hạ tầng	\N
7ee412dc-a9fa-42c0-ae04-01055c608678	2026-01-20	2026-01-20 20:00:00	2026-01-20 18:00:00	2026-01-20 18:00:00	2026-01-20 20:00:00	f	f	f	accepted	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	9fbc67a0-b671-479c-9b46-3076df068741	Tối ưu hóa dữ liệu khách hàng	\N
38caf6a3-6480-4321-909e-f49a2c5d081b	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hoan thanh bao cao tai chinh	\N
c843c37e-5c32-45e0-8121-7e37b769673f	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hoan thanh giao hang cuoi thang	\N
0fe5f83a-bc61-4afc-beb5-2194e2e42c07	2026-08-25	2026-08-25 19:30:00	2026-08-25 18:00:00	2026-08-25 18:00:00	2026-08-25 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Xử lý sự cố hạ tầng	\N
550b6192-df4b-493d-895b-11478884338f	2026-08-27	2026-08-27 20:30:00	2026-08-27 18:00:00	2026-08-27 18:00:00	2026-08-27 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hoàn tất báo cáo định kỳ	\N
8a1f61b2-15b5-45fc-871e-6e77997bba6a	2026-07-09	2026-07-09 19:30:00	2026-07-09 18:00:00	2026-07-09 18:00:00	2026-07-09 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hoàn tất báo cáo định kỳ	\N
64dfd301-b88b-4f8a-8c17-6d0ca7acfd30	2026-07-17	2026-07-17 19:30:00	2026-07-17 18:00:00	2026-07-17 18:00:00	2026-07-17 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Xử lý sự cố hạ tầng	\N
2f96d9da-c360-49a6-a638-b2a9c8539551	2026-06-02	2026-06-02 20:00:00	2026-06-02 18:00:00	2026-06-02 18:00:00	2026-06-02 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bàn giao dự án	\N
c3c830d8-28ae-4ab9-b25b-1488230dc786	2026-06-19	2026-06-19 19:30:00	2026-06-19 18:00:00	2026-06-19 18:00:00	2026-06-19 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Tối ưu hóa dữ liệu khách hàng	\N
1fd61881-a91e-464f-bc1d-0a7b720fdc01	2026-05-01	2026-05-01 19:30:00	2026-05-01 18:00:00	2026-05-01 18:00:00	2026-05-01 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Tối ưu hóa dữ liệu khách hàng	\N
eb6ab75c-a9dc-4861-a7f7-8c87946edd2d	2026-05-26	2026-05-26 20:00:00	2026-05-26 18:00:00	2026-05-26 18:00:00	2026-05-26 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hoàn tất báo cáo định kỳ	\N
df77481d-7c30-4a06-845b-81120124bf20	2026-04-20	2026-04-20 19:30:00	2026-04-20 18:00:00	2026-04-20 18:00:00	2026-04-20 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Xử lý sự cố hạ tầng	\N
050ace22-70ee-4080-a788-0849633a49b4	2026-04-24	2026-04-24 20:30:00	2026-04-24 18:00:00	2026-04-24 18:00:00	2026-04-24 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Xử lý sự cố hạ tầng	\N
a9dfa5c7-6e16-4be2-af27-66c08d072f3d	2026-03-27	2026-03-27 19:30:00	2026-03-27 18:00:00	2026-03-27 18:00:00	2026-03-27 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Tối ưu hóa dữ liệu khách hàng	\N
909d435e-2258-4bed-9861-d31e37814fc4	2026-02-23	2026-02-23 20:00:00	2026-02-23 18:00:00	2026-02-23 18:00:00	2026-02-23 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Xử lý sự cố hạ tầng	\N
939bf2b8-3a94-47f0-8919-755a4b3ea76a	2026-01-01	2026-01-01 20:30:00	2026-01-01 18:00:00	2026-01-01 18:00:00	2026-01-01 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hoàn tất báo cáo định kỳ	\N
be7d437f-99cc-421a-882a-c61948f07cbc	2026-01-26	2026-01-26 20:30:00	2026-01-26 18:00:00	2026-01-26 18:00:00	2026-01-26 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	Hỗ trợ bàn giao dự án	\N
a8549815-f921-4135-9346-65a94385c1be	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Hoan thanh bao cao tai chinh	\N
f94c35ba-a77e-4358-a816-74c82b8d6856	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Hoan thanh giao hang cuoi thang	\N
481c7c75-787b-46c4-996f-bca586dbac50	2026-08-18	2026-08-18 19:30:00	2026-08-18 18:00:00	2026-08-18 18:00:00	2026-08-18 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Xử lý sự cố hạ tầng	\N
11016dc5-bb6e-4fec-a1b9-c7d0adb7312b	2026-08-12	2026-08-12 19:30:00	2026-08-12 18:00:00	2026-08-12 18:00:00	2026-08-12 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Hoàn tất báo cáo định kỳ	\N
44216694-fee7-48fb-bee6-c35f349f5b80	2026-07-27	2026-07-27 19:30:00	2026-07-27 18:00:00	2026-07-27 18:00:00	2026-07-27 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Hoàn tất báo cáo định kỳ	\N
d5cf8fe3-1103-432d-9336-7c24f26cdb8b	2026-06-01	2026-06-01 20:00:00	2026-06-01 18:00:00	2026-06-01 18:00:00	2026-06-01 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Tối ưu hóa dữ liệu khách hàng	\N
eb49768b-97b5-4357-a2ae-f72a3a7f2a6b	2026-06-23	2026-06-23 20:00:00	2026-06-23 18:00:00	2026-06-23 18:00:00	2026-06-23 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Hoàn tất báo cáo định kỳ	\N
d1d52e8e-f143-4678-b7e5-bff26b6af2c2	2026-05-29	2026-05-29 20:30:00	2026-05-29 18:00:00	2026-05-29 18:00:00	2026-05-29 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Tối ưu hóa dữ liệu khách hàng	\N
5f928163-8468-44c2-b336-a54853457200	2026-05-22	2026-05-22 20:00:00	2026-05-22 18:00:00	2026-05-22 18:00:00	2026-05-22 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Xử lý sự cố hạ tầng	\N
061f831b-3124-45b5-b994-9d2c911a22d4	2026-04-20	2026-04-20 19:30:00	2026-04-20 18:00:00	2026-04-20 18:00:00	2026-04-20 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Xử lý sự cố hạ tầng	\N
d0d9b8f5-a137-4623-b1bf-aa0aa409b70d	2026-03-11	2026-03-11 19:30:00	2026-03-11 18:00:00	2026-03-11 18:00:00	2026-03-11 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Hoàn tất báo cáo định kỳ	\N
109644b8-9543-4d0e-bd0b-c8de84a89f2c	2026-03-13	2026-03-13 20:30:00	2026-03-13 18:00:00	2026-03-13 18:00:00	2026-03-13 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Hoàn tất báo cáo định kỳ	\N
a3946d17-2cd5-4ff7-b344-5aa8f1a72035	2026-02-05	2026-02-05 20:30:00	2026-02-05 18:00:00	2026-02-05 18:00:00	2026-02-05 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Tối ưu hóa dữ liệu khách hàng	\N
bfc7e9e1-a5f3-4f84-b337-394cac9fbae2	2026-01-14	2026-01-14 20:00:00	2026-01-14 18:00:00	2026-01-14 18:00:00	2026-01-14 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Hỗ trợ bàn giao dự án	\N
4891e640-88b5-438b-9682-5a99d912f374	2026-01-06	2026-01-06 20:00:00	2026-01-06 18:00:00	2026-01-06 18:00:00	2026-01-06 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	c6322771-714d-4d31-a732-47f86ac8465e	Xử lý sự cố hạ tầng	\N
be6eff38-9489-4cce-ac8c-767cca3f4f2a	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoan thanh bao cao tai chinh	\N
2692a064-26d4-47c3-86d2-e2204e9b6d12	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoan thanh giao hang cuoi thang	\N
897b1694-6949-470f-8e51-fdc6776d2d89	2026-08-31	2026-08-31 20:30:00	2026-08-31 18:00:00	2026-08-31 18:00:00	2026-08-31 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Xử lý sự cố hạ tầng	\N
9195ef54-065d-457d-8599-140afbda0d56	2026-08-04	2026-08-04 20:30:00	2026-08-04 18:00:00	2026-08-04 18:00:00	2026-08-04 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoàn tất báo cáo định kỳ	\N
cde252fb-4699-47a2-9129-f325dd570a34	2026-07-16	2026-07-16 19:30:00	2026-07-16 18:00:00	2026-07-16 18:00:00	2026-07-16 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Tối ưu hóa dữ liệu khách hàng	\N
ab19ceaf-5157-42fc-9e9d-4ec24ec5685c	2026-07-30	2026-07-30 19:30:00	2026-07-30 18:00:00	2026-07-30 18:00:00	2026-07-30 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoàn tất báo cáo định kỳ	\N
889fc452-d864-4158-a207-a2ba24f46208	2026-06-22	2026-06-22 19:30:00	2026-06-22 18:00:00	2026-06-22 18:00:00	2026-06-22 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoàn tất báo cáo định kỳ	\N
be706642-c1af-48e2-b67e-734a10852eab	2026-05-05	2026-05-05 20:00:00	2026-05-05 18:00:00	2026-05-05 18:00:00	2026-05-05 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoàn tất báo cáo định kỳ	\N
bcf37188-6e59-486d-87bf-edda9045a332	2026-04-30	2026-04-30 20:00:00	2026-04-30 18:00:00	2026-04-30 18:00:00	2026-04-30 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Xử lý sự cố hạ tầng	\N
3db24add-9b67-40d7-b7ee-c67b8088f346	2026-04-20	2026-04-20 20:30:00	2026-04-20 18:00:00	2026-04-20 18:00:00	2026-04-20 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Xử lý sự cố hạ tầng	\N
cae07a70-3df0-4990-bf1c-ae546a265aef	2026-03-31	2026-03-31 20:00:00	2026-03-31 18:00:00	2026-03-31 18:00:00	2026-03-31 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoàn tất báo cáo định kỳ	\N
312c1065-6aa3-4b9a-b808-8057d4e243fd	2026-03-06	2026-03-06 20:30:00	2026-03-06 18:00:00	2026-03-06 18:00:00	2026-03-06 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoàn tất báo cáo định kỳ	\N
40cac6c1-ab84-4da6-ba7f-d1cb5424804b	2026-02-27	2026-02-27 20:30:00	2026-02-27 18:00:00	2026-02-27 18:00:00	2026-02-27 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bàn giao dự án	\N
f975590a-dd50-4c16-a058-0447a4757ea4	2026-02-23	2026-02-23 20:00:00	2026-02-23 18:00:00	2026-02-23 18:00:00	2026-02-23 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bàn giao dự án	\N
51ccfa51-5745-4c28-9582-0790ac922c71	2026-01-08	2026-01-08 20:30:00	2026-01-08 18:00:00	2026-01-08 18:00:00	2026-01-08 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hoàn tất báo cáo định kỳ	\N
75c1852d-4df0-4976-ad01-ef58b499f134	2026-01-23	2026-01-23 20:30:00	2026-01-23 18:00:00	2026-01-23 18:00:00	2026-01-23 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	fca9aa46-b141-415f-ab4c-9f336bdfd46e	Hỗ trợ bàn giao dự án	\N
f5cf5483-1faf-447a-b922-ca09f8989e77	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hoan thanh bao cao tai chinh	\N
2e734e49-bf58-40fe-973c-2f3a2aaa1c75	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hoan thanh giao hang cuoi thang	\N
34cf473b-7e1b-4514-b130-e64e932380ae	2026-08-03	2026-08-03 20:00:00	2026-08-03 18:00:00	2026-08-03 18:00:00	2026-08-03 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Tối ưu hóa dữ liệu khách hàng	\N
4eedbb6f-3aaf-47f6-9608-e5dd9ad93b4b	2026-08-06	2026-08-06 20:30:00	2026-08-06 18:00:00	2026-08-06 18:00:00	2026-08-06 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hoàn tất báo cáo định kỳ	\N
c25baf6c-114a-4840-b0a6-438c069c0312	2026-07-20	2026-07-20 20:30:00	2026-07-20 18:00:00	2026-07-20 18:00:00	2026-07-20 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Xử lý sự cố hạ tầng	\N
7bcd8556-3360-4db1-b2aa-7b9f79d85ab1	2026-07-06	2026-07-06 20:00:00	2026-07-06 18:00:00	2026-07-06 18:00:00	2026-07-06 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Tối ưu hóa dữ liệu khách hàng	\N
0c7e49ab-fc8a-4e64-817f-32a862335cac	2026-06-01	2026-06-01 20:30:00	2026-06-01 18:00:00	2026-06-01 18:00:00	2026-06-01 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Tối ưu hóa dữ liệu khách hàng	\N
f3a6ead6-d8b4-42e2-b0da-8346bdde3048	2026-06-22	2026-06-22 20:00:00	2026-06-22 18:00:00	2026-06-22 18:00:00	2026-06-22 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hoàn tất báo cáo định kỳ	\N
d6e32493-8746-466a-a648-41e8758ea502	2026-05-12	2026-05-12 20:30:00	2026-05-12 18:00:00	2026-05-12 18:00:00	2026-05-12 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hoàn tất báo cáo định kỳ	\N
944713dd-a02a-4069-a357-031efe53d3d0	2026-04-20	2026-04-20 19:30:00	2026-04-20 18:00:00	2026-04-20 18:00:00	2026-04-20 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Tối ưu hóa dữ liệu khách hàng	\N
fb63f99a-cc7e-48c8-9c20-e4343e795786	2026-03-02	2026-03-02 20:00:00	2026-03-02 18:00:00	2026-03-02 18:00:00	2026-03-02 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hỗ trợ bàn giao dự án	\N
a27f949e-03fe-49f6-a46f-a2414d05a245	2026-02-18	2026-02-18 20:30:00	2026-02-18 18:00:00	2026-02-18 18:00:00	2026-02-18 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Hoàn tất báo cáo định kỳ	\N
70720871-3c76-445e-9c62-158278368da8	2026-01-07	2026-01-07 20:00:00	2026-01-07 18:00:00	2026-01-07 18:00:00	2026-01-07 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	Xử lý sự cố hạ tầng	\N
18a5ad11-9dde-4ad9-bfbf-8cac98d1b847	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hoan thanh bao cao tai chinh	\N
459effd2-a695-44ad-8899-1cefa62e5bf8	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hoan thanh giao hang cuoi thang	\N
22553784-faef-456c-913e-ad443ff73fd4	2026-08-10	2026-08-10 20:00:00	2026-08-10 18:00:00	2026-08-10 18:00:00	2026-08-10 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bàn giao dự án	\N
4f6e53e8-db20-4168-8711-9ae010d6adc7	2026-08-17	2026-08-17 19:30:00	2026-08-17 18:00:00	2026-08-17 18:00:00	2026-08-17 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hoàn tất báo cáo định kỳ	\N
40d3fd17-a388-4261-9ada-7cb9b57db0c5	2026-07-23	2026-07-23 20:30:00	2026-07-23 18:00:00	2026-07-23 18:00:00	2026-07-23 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Tối ưu hóa dữ liệu khách hàng	\N
3fbc4340-f3fd-4818-b13d-e373be674e4c	2026-07-08	2026-07-08 20:30:00	2026-07-08 18:00:00	2026-07-08 18:00:00	2026-07-08 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hoàn tất báo cáo định kỳ	\N
38dc94b3-7666-42e4-bc72-c676cef1d6eb	2026-06-19	2026-06-19 19:30:00	2026-06-19 18:00:00	2026-06-19 18:00:00	2026-06-19 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bàn giao dự án	\N
34906f76-b990-41c1-9096-38c162e168db	2026-05-11	2026-05-11 19:30:00	2026-05-11 18:00:00	2026-05-11 18:00:00	2026-05-11 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hỗ trợ bàn giao dự án	\N
42c469ce-66bd-4993-961d-840a9975a55d	2026-04-09	2026-04-09 20:00:00	2026-04-09 18:00:00	2026-04-09 18:00:00	2026-04-09 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hoàn tất báo cáo định kỳ	\N
79b24b44-64cd-43a1-9d89-5218fd08e16f	2026-03-25	2026-03-25 19:30:00	2026-03-25 18:00:00	2026-03-25 18:00:00	2026-03-25 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Hoàn tất báo cáo định kỳ	\N
3fe52618-efb1-41fe-9c12-dbef11daae04	2026-02-11	2026-02-11 19:30:00	2026-02-11 18:00:00	2026-02-11 18:00:00	2026-02-11 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Xử lý sự cố hạ tầng	\N
baa6f970-2ab7-4227-8a2c-521775aaf826	2026-01-28	2026-01-28 20:00:00	2026-01-28 18:00:00	2026-01-28 18:00:00	2026-01-28 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	Tối ưu hóa dữ liệu khách hàng	\N
476ade92-99c1-4eb8-bba7-911a0d145d83	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hoan thanh bao cao tai chinh	\N
9da7657a-e2b0-4374-b63a-d6e7f561e072	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hoan thanh giao hang cuoi thang	\N
ca5b62a8-ff4e-41fb-ab6a-6aebddbc3d18	2026-08-19	2026-08-19 20:00:00	2026-08-19 18:00:00	2026-08-19 18:00:00	2026-08-19 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bàn giao dự án	\N
357a6e7a-5728-4d60-b5a6-dfd4667908b5	2026-07-27	2026-07-27 19:30:00	2026-07-27 18:00:00	2026-07-27 18:00:00	2026-07-27 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bàn giao dự án	\N
581f5104-4a57-4ac4-9a72-3a0395025041	2026-07-20	2026-07-20 20:00:00	2026-07-20 18:00:00	2026-07-20 18:00:00	2026-07-20 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hoàn tất báo cáo định kỳ	\N
c6de4423-b527-41ab-b651-f6055817fc88	2026-06-30	2026-06-30 20:30:00	2026-06-30 18:00:00	2026-06-30 18:00:00	2026-06-30 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Tối ưu hóa dữ liệu khách hàng	\N
6c810fe6-a069-4866-94a2-ac930f75543f	2026-06-25	2026-06-25 19:30:00	2026-06-25 18:00:00	2026-06-25 18:00:00	2026-06-25 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bàn giao dự án	\N
043c0392-51cd-488f-a064-cefb51a715bc	2026-05-12	2026-05-12 20:00:00	2026-05-12 18:00:00	2026-05-12 18:00:00	2026-05-12 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hỗ trợ bàn giao dự án	\N
3c34d0e9-9c73-4ae8-9bd1-e961c013afea	2026-04-30	2026-04-30 20:00:00	2026-04-30 18:00:00	2026-04-30 18:00:00	2026-04-30 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hoàn tất báo cáo định kỳ	\N
9ccdbe9f-ec8c-471d-97b0-0d04d8b2f042	2026-04-13	2026-04-13 19:30:00	2026-04-13 18:00:00	2026-04-13 18:00:00	2026-04-13 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Xử lý sự cố hạ tầng	\N
760b4387-f66f-4a3b-a5c5-7372c896a614	2026-03-17	2026-03-17 19:30:00	2026-03-17 18:00:00	2026-03-17 18:00:00	2026-03-17 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Xử lý sự cố hạ tầng	\N
842372cd-6196-4a1c-954c-cb88fbe516ec	2026-02-19	2026-02-19 20:00:00	2026-02-19 18:00:00	2026-02-19 18:00:00	2026-02-19 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Xử lý sự cố hạ tầng	\N
6fedd2e0-d748-4a60-b00b-966883887f1b	2026-02-06	2026-02-06 19:30:00	2026-02-06 18:00:00	2026-02-06 18:00:00	2026-02-06 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hoàn tất báo cáo định kỳ	\N
8ea301be-c601-40ed-b2d2-0fbabc2413be	2026-01-06	2026-01-06 20:00:00	2026-01-06 18:00:00	2026-01-06 18:00:00	2026-01-06 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	Hoàn tất báo cáo định kỳ	\N
d018f5eb-ac60-4b82-8385-8d96bcefc9a5	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Hoan thanh bao cao tai chinh	\N
691d299e-308d-4734-b3a9-d6bb19c4ca54	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Hoan thanh giao hang cuoi thang	\N
ffc650f7-39b0-4d5b-a43b-73f2d9924604	2026-08-06	2026-08-06 20:00:00	2026-08-06 18:00:00	2026-08-06 18:00:00	2026-08-06 20:00:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bàn giao dự án	\N
5a2cde59-6d26-4c4b-99b2-409042d97cb5	2026-08-12	2026-08-12 20:30:00	2026-08-12 18:00:00	2026-08-12 18:00:00	2026-08-12 20:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Xử lý sự cố hạ tầng	\N
a0387adc-0097-478b-923f-a613a2f1d18b	2026-07-29	2026-07-29 19:30:00	2026-07-29 18:00:00	2026-07-29 18:00:00	2026-07-29 19:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Hoàn tất báo cáo định kỳ	\N
56ba54be-0461-40f2-a862-a9da053e70cb	2026-07-08	2026-07-08 20:30:00	2026-07-08 18:00:00	2026-07-08 18:00:00	2026-07-08 20:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bàn giao dự án	\N
a0ef148d-ab1d-4c70-ae80-d6073f0012c8	2026-06-05	2026-06-05 19:30:00	2026-06-05 18:00:00	2026-06-05 18:00:00	2026-06-05 19:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Xử lý sự cố hạ tầng	\N
0a64a63d-19f4-44c5-9c5e-10a9ebd7e0b1	2026-05-20	2026-05-20 20:30:00	2026-05-20 18:00:00	2026-05-20 18:00:00	2026-05-20 20:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Tối ưu hóa dữ liệu khách hàng	\N
bf976ea4-f5dc-4e48-9bb7-957187efe9eb	2026-04-02	2026-04-02 19:30:00	2026-04-02 18:00:00	2026-04-02 18:00:00	2026-04-02 19:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Hoàn tất báo cáo định kỳ	\N
07be31d5-f51c-42e4-93e7-a4e9335827dc	2026-04-07	2026-04-07 20:00:00	2026-04-07 18:00:00	2026-04-07 18:00:00	2026-04-07 20:00:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Hoàn tất báo cáo định kỳ	\N
a9a2a8e8-fa13-4c8b-8082-bc6b1503421a	2026-03-04	2026-03-04 20:30:00	2026-03-04 18:00:00	2026-03-04 18:00:00	2026-03-04 20:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Hỗ trợ bàn giao dự án	\N
44159e5c-12ed-440a-b5e5-abb3ce088853	2026-02-17	2026-02-17 19:30:00	2026-02-17 18:00:00	2026-02-17 18:00:00	2026-02-17 19:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Xử lý sự cố hạ tầng	\N
071c43c8-dec2-4cd4-ad96-22c2e30ee360	2026-01-07	2026-01-07 20:30:00	2026-01-07 18:00:00	2026-01-07 18:00:00	2026-01-07 20:30:00	f	f	f	accepted	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	5934b552-2406-4a70-b69b-f0abec6bdd28	Xử lý sự cố hạ tầng	\N
28909567-cb44-4256-aedf-5a1f9f38dd51	2026-09-18	2026-09-18 21:00:00	2026-09-18 19:00:00	2026-09-18 19:00:00	2026-09-18 21:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hoan thanh bao cao tai chinh	\N
8c80725f-5a20-4ad5-99ef-3ca5b94b1662	2026-09-11	2026-09-11 20:00:00	2026-09-11 18:00:00	2026-09-11 18:00:00	2026-09-11 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hoan thanh giao hang cuoi thang	\N
569c9566-2439-4d0a-85fd-cc5b4164ad2a	2026-08-11	2026-08-11 19:30:00	2026-08-11 18:00:00	2026-08-11 18:00:00	2026-08-11 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Tối ưu hóa dữ liệu khách hàng	\N
86408385-a56e-4368-9d25-eb925b8a3674	2026-07-27	2026-07-27 19:30:00	2026-07-27 18:00:00	2026-07-27 18:00:00	2026-07-27 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hoàn tất báo cáo định kỳ	\N
8fdc703c-6434-4044-81aa-373f0d7b241c	2026-06-09	2026-06-09 20:00:00	2026-06-09 18:00:00	2026-06-09 18:00:00	2026-06-09 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hoàn tất báo cáo định kỳ	\N
fbe69631-62a6-4aa7-8fd6-55998f0ea526	2026-06-05	2026-06-05 19:30:00	2026-06-05 18:00:00	2026-06-05 18:00:00	2026-06-05 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Tối ưu hóa dữ liệu khách hàng	\N
c81664b2-44c1-48cf-a1bf-7c3c8abe73aa	2026-05-28	2026-05-28 20:30:00	2026-05-28 18:00:00	2026-05-28 18:00:00	2026-05-28 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hoàn tất báo cáo định kỳ	\N
49e8713f-6327-473f-ae54-cfa4111a5aa6	2026-04-30	2026-04-30 19:30:00	2026-04-30 18:00:00	2026-04-30 18:00:00	2026-04-30 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Hỗ trợ bàn giao dự án	\N
d14734b2-2ce3-492c-95ea-e0672047582d	2026-03-18	2026-03-18 19:30:00	2026-03-18 18:00:00	2026-03-18 18:00:00	2026-03-18 19:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Xử lý sự cố hạ tầng	\N
77d717e4-36d5-485c-ac5e-4fb62e71d1ac	2026-02-11	2026-02-11 20:30:00	2026-02-11 18:00:00	2026-02-11 18:00:00	2026-02-11 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Tối ưu hóa dữ liệu khách hàng	\N
6ae1eb87-233b-4d0c-9aea-e9e4aae52c1c	2026-02-24	2026-02-24 20:30:00	2026-02-24 18:00:00	2026-02-24 18:00:00	2026-02-24 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Xử lý sự cố hạ tầng	\N
1f57bc58-1e98-4794-b98a-eedda13f1e88	2026-01-05	2026-01-05 20:30:00	2026-01-05 18:00:00	2026-01-05 18:00:00	2026-01-05 20:30:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Tối ưu hóa dữ liệu khách hàng	\N
187afd93-b4d6-44b5-a42e-2c6469b9763e	2026-01-29	2026-01-29 20:00:00	2026-01-29 18:00:00	2026-01-29 18:00:00	2026-01-29 20:00:00	f	f	f	accepted	5934b552-2406-4a70-b69b-f0abec6bdd28	6b39462f-1134-4e9a-9a06-f2b3687940b7	Tối ưu hóa dữ liệu khách hàng	\N
\.


--
-- Data for Name: payrolls; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payrolls (payroll_id, user_id, timesheet_id, period_month, period_year, base_salary, hourly_rate, basic_pay, overtime_pay, allowance_pay, bonus_pay, gross_pay, insurance_deduction, tax_deduction, other_deduction, total_deduction, net_pay, status, note, calculated_at, approved_at, paid_at, created_at, updated_at) FROM stdin;
a8470282-6877-4a0b-9b5d-8dbdbd501ee5	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	414b3276-51fd-427b-a6e1-a3e2f4220ce9	1	2026	195000000.00	1160714.29	195000000.00	5223214.31	1000000.00	0.00	201223214.31	20475000.00	49561875.01	0.00	70036875.01	131186339.30	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
307dc85e-4f25-4934-884a-44a3fb0ccd5c	5934b552-2406-4a70-b69b-f0abec6bdd28	e0929fd0-5f92-472d-8122-1bb11259b67b	1	2026	65000000.00	386904.76	65000000.00	1450892.85	1000000.00	0.00	67450892.85	6825000.00	9156473.21	0.00	15981473.21	51469419.64	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
a7cf7ad2-924a-482e-b381-dd0dc1a10936	6b39462f-1134-4e9a-9a06-f2b3687940b7	3af93799-5915-4378-8d8b-8ad90d806dae	1	2026	50000000.00	297619.05	50000000.00	2008928.59	1000000.00	0.00	53008928.59	5250000.00	5939732.15	0.00	11189732.15	41819196.44	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
6c8a381d-6ea3-4761-ae02-c270564dd51a	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	cc01e4b4-37da-4537-a86a-6c8c56038601	1	2026	30000000.00	178571.43	30000000.00	1339285.73	1000000.00	0.00	32339285.73	3150000.00	1987857.15	0.00	5137857.15	27201428.58	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
31a2da2d-b2d1-40a6-b99c-79398766cfa4	c6322771-714d-4d31-a732-47f86ac8465e	b2c88df1-bab7-40ba-a85f-74e784cbc863	1	2026	30000000.00	178571.43	30000000.00	1071428.58	1000000.00	0.00	32071428.58	3150000.00	1938214.29	0.00	5088214.29	26983214.29	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
baaf13b1-14c8-489e-9ba4-4978e3df49b0	fca9aa46-b141-415f-ab4c-9f336bdfd46e	222d90f6-3f91-4d7e-92ce-aa0ccb2ffd74	1	2026	30000000.00	178571.43	30000000.00	1339285.73	1000000.00	0.00	32339285.73	3150000.00	1987857.15	0.00	5137857.15	27201428.58	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
92872dcc-0e6b-4946-8dd4-588ce3415e78	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f9068774-e4c5-414f-b1b6-9d2bd7b38c10	1	2026	35000000.00	208333.33	35000000.00	624999.99	1000000.00	0.00	36624999.99	3675000.00	2740000.00	0.00	6415000.00	30209999.99	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
8f6ffbaa-d86b-40da-a5f6-feff89c6c75b	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	3f11838b-4bbc-4b07-9b5a-5f5ae3feee87	1	2026	28000000.00	166666.67	28000000.00	500000.01	1000000.00	0.00	29500000.01	2940000.00	1584000.00	0.00	4524000.00	24976000.01	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
38cdaa1c-5310-420f-8a97-ced5b3e84f2f	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	834a9b62-6eb1-491d-bdcc-dc90457a525f	1	2026	35000000.00	208333.33	35000000.00	624999.99	1000000.00	0.00	36624999.99	3675000.00	2740000.00	0.00	6415000.00	30209999.99	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
182f0ffe-1909-4629-940b-b51ee68bac55	d1f7cf77-4784-4b35-8d12-f2833e3bb066	fecf5c28-5960-497e-a6e3-6e2c4b30b9ba	1	2026	15000000.00	89285.71	15000000.00	200892.85	1000000.00	0.00	16200892.85	1575000.00	181294.64	0.00	1756294.64	14444598.21	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
07649b19-fd9d-4405-b848-82f2f725465e	951f937f-2724-4cf5-9b4f-7528f736d782	cea03b1c-5589-484f-a060-3f30092cfc86	1	2026	15000000.00	89285.71	15000000.00	200892.85	1000000.00	0.00	16200892.85	1575000.00	181294.64	0.00	1756294.64	14444598.21	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
aa8691d5-dc06-4c1f-91c0-e79ba82418bf	35337165-e0d0-4dd1-9c67-cc48180363af	6fd70965-67d6-48dd-a903-27641ce8571f	1	2026	15000000.00	89285.71	15000000.00	267857.13	1000000.00	0.00	16267857.13	1575000.00	184642.86	0.00	1759642.86	14508214.27	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
38d6afca-c6b1-4e8a-b434-ef4a346fed3a	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	30682aff-28d7-4a67-aac7-fb735dbbec58	1	2026	15000000.00	89285.71	15000000.00	602678.54	1000000.00	0.00	16602678.54	1575000.00	201383.93	0.00	1776383.93	14826294.61	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
fff4b486-0ecf-47f5-81f0-bb0fdb408e7c	9fbc67a0-b671-479c-9b46-3076df068741	cb157d0f-4f07-4d2c-b422-8d68f4f63567	1	2026	15000000.00	89285.71	15000000.00	468749.98	1000000.00	0.00	16468749.98	1575000.00	194687.50	0.00	1769687.50	14699062.48	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
370dfeed-deb9-4556-833a-67fe937fed9b	cf26d867-49f1-4c12-b35b-c79bfb2884fc	8432f093-7825-4e66-8921-6ac931334e4c	1	2026	15000000.00	89285.71	15000000.00	267857.13	1000000.00	0.00	16267857.13	1575000.00	184642.86	0.00	1759642.86	14508214.27	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
83ba713d-63f3-4094-9c0c-324d00efcf89	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	e4743ddb-8f86-44d6-b196-2b24f517dd58	1	2026	25000000.00	148809.52	25000000.00	334821.42	1000000.00	0.00	26334821.42	2625000.00	1156473.21	0.00	3781473.21	22553348.21	PAID	\N	2026-01-26 14:00:00+07	2026-01-27 16:00:00+07	2026-01-28 10:00:00+07	2026-01-26 14:00:00	2026-01-26 14:00:00
eac1169d-c3fb-457a-9764-06cd265e4282	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	bed50a0d-8934-4fed-a205-5582df36e304	2	2026	195000000.00	1625000.00	195000000.00	3656250.00	1000000.00	0.00	199656250.00	20475000.00	49013437.50	0.00	69488437.50	130167812.50	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
baebee26-a5e5-447a-965b-58d6cd6d1f84	5934b552-2406-4a70-b69b-f0abec6bdd28	92d5dfbe-1e67-40a1-87c8-cfe2b3cb2fb4	2	2026	65000000.00	541666.67	65000000.00	1218750.01	1000000.00	0.00	67218750.01	6825000.00	9098437.50	0.00	15923437.50	51295312.51	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
3ffb25a5-3ab2-40ae-9961-4f34bb007f88	6b39462f-1134-4e9a-9a06-f2b3687940b7	fa9828a1-1ce8-440c-a3b4-becbd68b15da	2	2026	50000000.00	416666.67	50000000.00	3125000.03	1000000.00	0.00	54125000.03	5250000.00	6218750.01	0.00	11468750.01	42656250.02	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
7eab5760-739a-4fc3-854e-4505ebf8e663	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	30b1eb13-9dfe-4e0d-b445-be99e7c83076	2	2026	30000000.00	250000.00	30000000.00	750000.00	1000000.00	0.00	31750000.00	3150000.00	1890000.00	0.00	5040000.00	26710000.00	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
39064ee4-3f0b-4c91-89df-cc8b15bfdcb7	c6322771-714d-4d31-a732-47f86ac8465e	4a50fcb0-d5b8-49c2-a590-6ada7e96e4c4	2	2026	30000000.00	250000.00	30000000.00	937500.00	1000000.00	0.00	31937500.00	3150000.00	1918125.00	0.00	5068125.00	26869375.00	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
51fa1547-965e-492e-9a5a-94d08023ff51	fca9aa46-b141-415f-ab4c-9f336bdfd46e	f5004dfb-0cd6-483f-af55-928fcbe605e3	2	2026	30000000.00	250000.00	30000000.00	1687500.00	1000000.00	0.00	32687500.00	3150000.00	2057500.00	0.00	5207500.00	27480000.00	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
cd9595d1-ccdd-4449-bca1-6000b715b135	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	c9c4a0a3-f7ac-48d7-8456-1e380921b0ef	2	2026	35000000.00	291666.67	35000000.00	1093750.01	1000000.00	0.00	37093750.01	3675000.00	2833750.00	0.00	6508750.00	30585000.01	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
c5d3a7e4-05d5-4d5b-8a6d-13d5dec05a11	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	ae2e7a3f-7ecc-4409-89f4-b8b80a51fa68	2	2026	28000000.00	233333.33	28000000.00	524999.99	1000000.00	0.00	29524999.99	2940000.00	1587750.00	0.00	4527750.00	24997249.99	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
37413d25-b3ef-4cfb-a972-b5ce0e3c1787	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	1568903a-ebf6-48ea-abe1-0cffa2741ca3	2	2026	35000000.00	291666.67	35000000.00	1531250.02	1000000.00	0.00	37531250.02	3675000.00	2921250.00	0.00	6596250.00	30935000.02	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
343eef5e-3290-4e93-807a-a8e5bc903ba9	d1f7cf77-4784-4b35-8d12-f2833e3bb066	f5e47bde-425a-4636-9485-6ac49898da6c	2	2026	15000000.00	125000.00	15000000.00	468750.00	1000000.00	0.00	16468750.00	1575000.00	194687.50	0.00	1769687.50	14699062.50	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
82756889-3a02-4eb3-b2a0-04e2378219dd	951f937f-2724-4cf5-9b4f-7528f736d782	be97e312-977e-4339-aec4-162f2eea99cb	2	2026	15000000.00	125000.00	15000000.00	281250.00	1000000.00	0.00	16281250.00	1575000.00	185312.50	0.00	1760312.50	14520937.50	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
549d23d4-03a7-47f9-8729-f5074dbdc786	35337165-e0d0-4dd1-9c67-cc48180363af	e46e89b7-b81f-4219-b412-6940f06c453d	2	2026	15000000.00	125000.00	15000000.00	375000.00	1000000.00	0.00	16375000.00	1575000.00	190000.00	0.00	1765000.00	14610000.00	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
3bcc4ce9-5050-4e22-b905-acfdf76f50b6	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	5f468820-7d72-44e1-bed8-e762c2a3220f	2	2026	15000000.00	125000.00	15000000.00	656250.00	1000000.00	0.00	16656250.00	1575000.00	204062.50	0.00	1779062.50	14877187.50	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
1cdabf66-46aa-4a8e-a733-f34aca189b05	9fbc67a0-b671-479c-9b46-3076df068741	958cfb24-81f1-4718-9b12-6278acd73960	2	2026	15000000.00	125000.00	15000000.00	843750.00	1000000.00	0.00	16843750.00	1575000.00	213437.50	0.00	1788437.50	15055312.50	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
7b3319ce-8d75-4093-9944-7ed671a87a8a	cf26d867-49f1-4c12-b35b-c79bfb2884fc	08062f71-1744-4ee7-9a7b-ae31b37b489e	2	2026	15000000.00	125000.00	15000000.00	375000.00	1000000.00	0.00	16375000.00	1575000.00	190000.00	0.00	1765000.00	14610000.00	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
8266b28c-f800-40ea-a355-2a8af45e1b57	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	4bb57d2d-19dc-4f55-a6cb-560e94154d0e	2	2026	25000000.00	208333.33	25000000.00	781249.99	1000000.00	0.00	26781249.99	2625000.00	1223437.50	0.00	3848437.50	22932812.49	PAID	\N	2026-02-26 14:00:00+07	2026-02-27 16:00:00+07	2026-02-28 10:00:00+07	2026-02-26 14:00:00	2026-02-26 14:00:00
bd854448-ba77-4c92-ad59-96fe7a6d214f	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	2d247a6f-0360-4ba3-b2ec-e707722b1b90	3	2026	195000000.00	1107954.55	195000000.00	5816761.39	1000000.00	500000.00	202316761.39	20475000.00	49944616.49	0.00	70419616.49	131897144.90	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
4ebd4e39-b3f6-4875-8999-f272106f6950	5934b552-2406-4a70-b69b-f0abec6bdd28	e282243b-64ff-4f48-b158-c2514bf0cebf	3	2026	65000000.00	369318.18	65000000.00	1384943.18	1000000.00	500000.00	67884943.18	6825000.00	9264985.79	0.00	16089985.79	51794957.39	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
311a5079-0626-434f-a071-513a907aa9f4	6b39462f-1134-4e9a-9a06-f2b3687940b7	3e5e9812-48a8-4c7a-8ddf-84017585d4da	3	2026	50000000.00	284090.91	50000000.00	639204.55	1000000.00	500000.00	52139204.55	5250000.00	5722301.14	0.00	10972301.14	41166903.41	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
adac57b6-0a86-46f0-a346-e2ddefc48a87	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	404b3eb6-0275-4f1b-8688-ca657013d460	3	2026	30000000.00	170454.55	30000000.00	383522.74	1000000.00	500000.00	31883522.74	3150000.00	1910028.41	0.00	5060028.41	26823494.33	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
9822268d-9ca5-42e4-951f-9e599fa89321	c6322771-714d-4d31-a732-47f86ac8465e	e72ff0df-0673-4b22-8013-2fe2258e60e5	3	2026	30000000.00	170454.55	30000000.00	1022727.30	1000000.00	500000.00	32522727.30	3150000.00	2024545.46	0.00	5174545.46	27348181.84	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
ab6a7e18-c8ab-4dd3-90ff-3bc253382c1c	fca9aa46-b141-415f-ab4c-9f336bdfd46e	d81636d8-2100-45bc-b547-3f239a1050e6	3	2026	30000000.00	170454.55	30000000.00	1150568.21	1000000.00	500000.00	32650568.21	3150000.00	2050113.64	0.00	5200113.64	27450454.57	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
c3f0a4bb-95b0-430e-87ef-6d04cbbfc871	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	cd7a9a83-5669-4b9c-b62f-5f06eb8dec2d	3	2026	35000000.00	198863.64	35000000.00	596590.92	1000000.00	500000.00	37096590.92	3675000.00	2834318.18	0.00	6509318.18	30587272.74	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
5e77e5b2-cf4e-43c1-afbb-c5ad804a5906	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	1bf758c1-477b-4f48-8730-681dfa902345	3	2026	28000000.00	159090.91	28000000.00	357954.55	1000000.00	500000.00	29857954.55	2940000.00	1637693.18	0.00	4577693.18	25280261.37	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
3cc93cbe-2f14-4eb2-9ddc-b6c80d36e2e0	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	549c3e23-ee9a-4c09-8783-b1fbd07d11a3	3	2026	35000000.00	198863.64	35000000.00	447443.19	1000000.00	500000.00	36947443.19	3675000.00	2804488.64	0.00	6479488.64	30467954.55	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
9709ed3c-585d-4be6-8d42-9d3cf31ccd05	d1f7cf77-4784-4b35-8d12-f2833e3bb066	9a4f40ef-7b68-4102-83ee-20b18965413a	3	2026	15000000.00	85227.27	15000000.00	575284.07	1000000.00	500000.00	17075284.07	1575000.00	225014.20	0.00	1800014.20	15275269.87	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
3d2cfc29-3d35-41f9-91b6-4f32ad07943b	951f937f-2724-4cf5-9b4f-7528f736d782	81ef2c00-6e2c-46b8-8fb8-ac88396039f0	3	2026	15000000.00	85227.27	15000000.00	447443.17	1000000.00	500000.00	16947443.17	1575000.00	218622.16	0.00	1793622.16	15153821.01	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
02034b01-c4a1-4f2e-8198-34c1c49589b1	35337165-e0d0-4dd1-9c67-cc48180363af	0fc8cbb2-1fc3-4c85-beb7-2b02da1b52b9	3	2026	15000000.00	85227.27	15000000.00	383522.72	1000000.00	500000.00	16883522.72	1575000.00	215426.14	0.00	1790426.14	15093096.58	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
93f2f21c-888e-4cbf-81ff-177cb62e9df0	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	0b1866e4-dddf-43a7-94e4-16a67d533a0c	3	2026	15000000.00	85227.27	15000000.00	447443.17	1000000.00	500000.00	16947443.17	1575000.00	218622.16	0.00	1793622.16	15153821.01	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
732dc67a-3f84-4e41-8219-e4fdb8fdc013	9fbc67a0-b671-479c-9b46-3076df068741	44267bef-88c7-4157-a155-9790fbdbc8f2	3	2026	15000000.00	85227.27	15000000.00	191761.36	1000000.00	500000.00	16691761.36	1575000.00	205838.07	0.00	1780838.07	14910923.29	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
94b40cfa-5d9f-415f-8c96-1123d9f266d6	cf26d867-49f1-4c12-b35b-c79bfb2884fc	1ae1e63e-b0d1-4c97-8574-9f3e54ecccb6	3	2026	15000000.00	85227.27	15000000.00	319602.26	1000000.00	500000.00	16819602.26	1575000.00	212230.11	0.00	1787230.11	15032372.15	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
1f30e681-262e-4acc-b568-4785b564fb90	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	82ce7bac-e393-47b9-947a-eddac2442351	3	2026	25000000.00	142045.45	25000000.00	319602.26	1000000.00	500000.00	26819602.26	2625000.00	1229190.34	0.00	3854190.34	22965411.92	PAID	\N	2026-03-26 14:00:00+07	2026-03-27 16:00:00+07	2026-03-28 10:00:00+07	2026-03-26 14:00:00	2026-03-26 14:00:00
8d7de5c9-6382-458f-a66e-a5df98321365	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	7e14825a-d4a5-4743-8d81-c04fe2dc4d80	4	2026	195000000.00	1218750.00	195000000.00	4570312.50	1000000.00	0.00	200570312.50	20475000.00	49333359.37	0.00	69808359.37	130761953.13	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
0e8e8079-e94c-486f-beaf-92c8238e2f83	5934b552-2406-4a70-b69b-f0abec6bdd28	ccce95ed-e9ca-48cd-b966-6e3a5e32f283	4	2026	65000000.00	406250.00	65000000.00	2132812.50	1000000.00	0.00	68132812.50	6825000.00	9326953.12	0.00	16151953.12	51980859.38	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
31d9a2c2-088f-416f-bb65-fbc33bfe416a	6b39462f-1134-4e9a-9a06-f2b3687940b7	8860a197-d155-4234-ad0b-1a3a311be434	4	2026	50000000.00	312500.00	50000000.00	703125.00	1000000.00	0.00	51703125.00	5250000.00	5613281.25	0.00	10863281.25	40839843.75	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
225d95d5-0e1c-4189-9bb0-54dcf46416ac	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	92447907-a318-458d-856b-4c40179296c8	4	2026	30000000.00	187500.00	30000000.00	1125000.00	1000000.00	0.00	32125000.00	3150000.00	1946250.00	0.00	5096250.00	27028750.00	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
e3d51a82-4ff4-4d7c-af56-f9e7a56525e4	c6322771-714d-4d31-a732-47f86ac8465e	3dbc6cb7-3d59-446a-b1c1-ba4118f20dca	4	2026	30000000.00	187500.00	30000000.00	421875.00	1000000.00	0.00	31421875.00	3150000.00	1840781.25	0.00	4990781.25	26431093.75	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
bb44418f-81ae-4bd9-8d78-4b8ed0608740	fca9aa46-b141-415f-ab4c-9f336bdfd46e	9dca3e65-34bb-438f-a3a4-408565e4b1ac	4	2026	30000000.00	187500.00	30000000.00	1265625.00	1000000.00	0.00	32265625.00	3150000.00	1973125.00	0.00	5123125.00	27142500.00	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
46635810-eda5-4f12-bb49-721f2a9c770c	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	d35458c3-879a-4420-95c0-1bd5a62dc584	4	2026	35000000.00	218750.00	35000000.00	492187.50	1000000.00	0.00	36492187.50	3675000.00	2713437.50	0.00	6388437.50	30103750.00	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
85f6401c-1f80-4351-9bfa-dd208563c9f1	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	15587f7e-fbda-4625-b4c2-bc0f3fb8c7ef	4	2026	28000000.00	175000.00	28000000.00	525000.00	1000000.00	0.00	29525000.00	2940000.00	1587750.00	0.00	4527750.00	24997250.00	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
80793e70-358d-46ef-a9ad-f6a1073febc5	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	a620811f-7725-4915-adbe-12175b73a893	4	2026	35000000.00	218750.00	35000000.00	1148437.50	1000000.00	0.00	37148437.50	3675000.00	2844687.50	0.00	6519687.50	30628750.00	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
41b1203e-f3e1-4043-8d87-c1330a45d46e	d1f7cf77-4784-4b35-8d12-f2833e3bb066	25bcdfac-b6ac-4b51-9179-9e5fd8abde81	4	2026	15000000.00	93750.00	15000000.00	632812.50	1000000.00	0.00	16632812.50	1575000.00	202890.62	0.00	1777890.62	14854921.88	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
79f7962e-8cf7-48d2-826a-aedd357ac830	951f937f-2724-4cf5-9b4f-7528f736d782	79957885-16e5-4ed7-a3e5-eccacabc3063	4	2026	15000000.00	93750.00	15000000.00	281250.00	1000000.00	0.00	16281250.00	1575000.00	185312.50	0.00	1760312.50	14520937.50	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
2d38ce27-ea03-4523-83cc-6292a7397776	35337165-e0d0-4dd1-9c67-cc48180363af	9e12cd99-a773-47c8-8b08-63320dce499b	4	2026	15000000.00	93750.00	15000000.00	632812.50	1000000.00	0.00	16632812.50	1575000.00	202890.62	0.00	1777890.62	14854921.88	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
3cfae9c3-ecd0-4ee4-95a3-7edc1539e920	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	927997a0-e3a5-4f7f-a81c-daa1686153a3	4	2026	15000000.00	93750.00	15000000.00	562500.00	1000000.00	0.00	16562500.00	1575000.00	199375.00	0.00	1774375.00	14788125.00	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
8acf7afc-5528-4bf3-ae9a-c53fc96a4682	9fbc67a0-b671-479c-9b46-3076df068741	17b8619c-6b11-4122-844a-106f84570ab4	4	2026	15000000.00	93750.00	15000000.00	492187.50	1000000.00	0.00	16492187.50	1575000.00	195859.38	0.00	1770859.38	14721328.12	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
6e48ffc5-5dec-4eb1-867c-516b1afb96d5	cf26d867-49f1-4c12-b35b-c79bfb2884fc	e1867584-f9b1-4367-9865-0110fa270205	4	2026	15000000.00	93750.00	15000000.00	281250.00	1000000.00	0.00	16281250.00	1575000.00	185312.50	0.00	1760312.50	14520937.50	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
d9fb7ae3-9c21-4b97-8466-9bc3ec959ab8	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	4aec699d-b19b-4564-9092-312946a679b0	4	2026	25000000.00	156250.00	25000000.00	585937.50	1000000.00	0.00	26585937.50	2625000.00	1194140.62	0.00	3819140.62	22766796.88	PAID	\N	2026-04-26 14:00:00+07	2026-04-27 16:00:00+07	2026-04-28 10:00:00+07	2026-04-26 14:00:00	2026-04-26 14:00:00
b93a1350-cdcf-4f5e-b8b6-d1d8f6d16575	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	2ce69ae0-a1c8-4903-82b4-925a99f3ae1f	5	2026	195000000.00	1218750.00	195000000.00	9140625.00	1000000.00	0.00	205140625.00	20475000.00	50932968.75	0.00	71407968.75	133732656.25	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
1d43de60-0863-4491-b688-abb11c7a6ffc	5934b552-2406-4a70-b69b-f0abec6bdd28	7d85199f-5e2c-4eaf-9acc-8625923f9c13	5	2026	65000000.00	406250.00	65000000.00	1523437.50	1000000.00	0.00	67523437.50	6825000.00	9174609.38	0.00	15999609.38	51523828.12	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
8062d0a4-3d8c-4410-b72d-f449a0bc980b	6b39462f-1134-4e9a-9a06-f2b3687940b7	147ad841-bdc6-4166-aecc-57e6d84e9335	5	2026	50000000.00	312500.00	50000000.00	1171875.00	1000000.00	0.00	52171875.00	5250000.00	5730468.75	0.00	10980468.75	41191406.25	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
ba7f83e7-d8a2-459f-b137-2bd6422d8fde	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	b31f33f3-68a5-4189-a1ad-2b88d6f6d8b6	5	2026	30000000.00	187500.00	30000000.00	984375.00	1000000.00	0.00	31984375.00	3150000.00	1925156.25	0.00	5075156.25	26909218.75	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
8c0d1296-d997-44d9-85e2-589d49f31396	c6322771-714d-4d31-a732-47f86ac8465e	96d125bf-811e-4a6f-9a15-3031907520fe	5	2026	30000000.00	187500.00	30000000.00	1265625.00	1000000.00	0.00	32265625.00	3150000.00	1973125.00	0.00	5123125.00	27142500.00	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
931b4648-998d-4373-a8ce-9d8966853ca2	fca9aa46-b141-415f-ab4c-9f336bdfd46e	1a6aff5b-c02c-4ffe-b437-2dc2547c3699	5	2026	30000000.00	187500.00	30000000.00	562500.00	1000000.00	0.00	31562500.00	3150000.00	1861875.00	0.00	5011875.00	26550625.00	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
8fea792c-398d-4608-bcf5-ed396e2e51c5	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	d85090c3-8277-4a25-94d3-984e334f4c98	5	2026	35000000.00	218750.00	35000000.00	820312.50	1000000.00	0.00	36820312.50	3675000.00	2779062.50	0.00	6454062.50	30366250.00	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
7ccc25b1-afdd-4ac5-8001-4c550cb42206	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	7c5f68e1-61f5-498f-b041-d14e0fe7fdb5	5	2026	28000000.00	175000.00	28000000.00	393750.00	1000000.00	0.00	29393750.00	2940000.00	1568062.50	0.00	4508062.50	24885687.50	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
bfbfe40d-a4ec-4f21-9916-f1a28af9f758	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	03bc2a32-fc90-48a4-978a-2ecbd712d887	5	2026	35000000.00	218750.00	35000000.00	656250.00	1000000.00	0.00	36656250.00	3675000.00	2746250.00	0.00	6421250.00	30235000.00	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
d80a0476-34aa-4d98-baca-a9e179cfd836	d1f7cf77-4784-4b35-8d12-f2833e3bb066	081e0396-083b-45a7-b4d9-c6a97b5f945e	5	2026	15000000.00	93750.00	15000000.00	492187.50	1000000.00	0.00	16492187.50	1575000.00	195859.38	0.00	1770859.38	14721328.12	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
91005c71-a785-4c04-b9d0-8c9ff5d5b508	951f937f-2724-4cf5-9b4f-7528f736d782	2f97d967-75aa-4168-961d-13860ba13d6b	5	2026	15000000.00	93750.00	15000000.00	351562.50	1000000.00	0.00	16351562.50	1575000.00	188828.12	0.00	1763828.12	14587734.38	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
1fee445d-8dfb-4336-930b-abf5298ac740	35337165-e0d0-4dd1-9c67-cc48180363af	1d52d2ea-9f79-4280-b946-0a10780d9701	5	2026	15000000.00	93750.00	15000000.00	210937.50	1000000.00	0.00	16210937.50	1575000.00	181796.88	0.00	1756796.88	14454140.62	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
d75308aa-2dd8-4239-9d05-cb2bc81067f5	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	b4570934-2886-4995-9271-cf72b4604963	5	2026	15000000.00	93750.00	15000000.00	492187.50	1000000.00	0.00	16492187.50	1575000.00	195859.38	0.00	1770859.38	14721328.12	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
0c184a61-829a-4cae-b858-99e5cf974d4b	9fbc67a0-b671-479c-9b46-3076df068741	fd03caa1-e4c7-49a3-92c7-e0c7e248b173	5	2026	15000000.00	93750.00	15000000.00	632812.50	1000000.00	0.00	16632812.50	1575000.00	202890.62	0.00	1777890.62	14854921.88	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
f365450a-b0f3-4985-a4fa-60b8c7825b69	cf26d867-49f1-4c12-b35b-c79bfb2884fc	353a814e-def1-472d-9a06-2d83b08e9ad7	5	2026	15000000.00	93750.00	15000000.00	492187.50	1000000.00	0.00	16492187.50	1575000.00	195859.38	0.00	1770859.38	14721328.12	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
72555d02-f41e-4458-af8e-c221d477e4cc	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	75309f98-65fe-4a05-99e2-63fd232fecb7	5	2026	25000000.00	156250.00	25000000.00	820312.50	1000000.00	0.00	26820312.50	2625000.00	1229296.88	0.00	3854296.88	22966015.62	PAID	\N	2026-05-26 14:00:00+07	2026-05-27 16:00:00+07	2026-05-28 10:00:00+07	2026-05-26 14:00:00	2026-05-26 14:00:00
bb7f6cb0-89b7-4162-91ae-bf007d66e906	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	6c38445a-2a53-4c99-b81f-ad3898e69869	6	2026	195000000.00	1107954.55	195000000.00	3323863.65	1000000.00	500000.00	199823863.65	20475000.00	49072102.28	0.00	69547102.28	130276761.37	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
f4623b7d-6600-40ba-a864-e1f185e5d251	5934b552-2406-4a70-b69b-f0abec6bdd28	b283af7a-bdb8-4919-b91e-4ea42e8f5f49	6	2026	65000000.00	369318.18	65000000.00	830965.91	1000000.00	500000.00	67330965.91	6825000.00	9126491.48	0.00	15951491.48	51379474.43	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
25a42a67-557a-40de-87cd-36a4be3c6201	6b39462f-1134-4e9a-9a06-f2b3687940b7	b5a9bcd1-2617-458c-b26e-b3edde9ac78a	6	2026	50000000.00	284090.91	50000000.00	1491477.28	1000000.00	500000.00	52991477.28	5250000.00	5935369.32	0.00	11185369.32	41806107.96	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
9f5d71ce-f404-4556-9824-b99291abd25e	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	d65ceb69-96ea-4793-9a17-32946ee38b1f	6	2026	30000000.00	170454.55	30000000.00	894886.39	1000000.00	500000.00	32394886.39	3150000.00	1998977.28	0.00	5148977.28	27245909.11	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
6b9a132a-9c7f-4348-bf0a-86d25ceffc7d	c6322771-714d-4d31-a732-47f86ac8465e	393f3883-dee2-4ee4-aa5b-92d963c605b3	6	2026	30000000.00	170454.55	30000000.00	1022727.30	1000000.00	500000.00	32522727.30	3150000.00	2024545.46	0.00	5174545.46	27348181.84	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
f8ac9ebe-2556-4f69-b858-d39839e1d6f3	fca9aa46-b141-415f-ab4c-9f336bdfd46e	0b9f1080-99aa-4fb4-9ddc-0dd7122d7757	6	2026	30000000.00	170454.55	30000000.00	383522.74	1000000.00	500000.00	31883522.74	3150000.00	1910028.41	0.00	5060028.41	26823494.33	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
263f5b48-3c60-492c-82a2-721742d0e67c	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	bc0a33af-89c0-4d97-82d3-b68cbe8f9905	6	2026	35000000.00	198863.64	35000000.00	1342329.57	1000000.00	500000.00	37842329.57	3675000.00	2983465.91	0.00	6658465.91	31183863.66	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
f9306102-a9f5-4010-83d4-9f0150de8860	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	edcd9150-40c2-4959-96d6-eed41e939bb7	6	2026	28000000.00	159090.91	28000000.00	357954.55	1000000.00	500000.00	29857954.55	2940000.00	1637693.18	0.00	4577693.18	25280261.37	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
d5f93e17-8909-4e03-bf46-e02f5e4abc27	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	48b41ca4-65ec-4d7e-8b09-1ce4ca89f303	6	2026	35000000.00	198863.64	35000000.00	1193181.84	1000000.00	500000.00	37693181.84	3675000.00	2953636.37	0.00	6628636.37	31064545.47	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
fc24712f-70f1-4081-9271-13fdea1feafb	d1f7cf77-4784-4b35-8d12-f2833e3bb066	d434e92a-1e10-4cd7-a0ba-9de7eb923a86	6	2026	15000000.00	85227.27	15000000.00	191761.36	1000000.00	500000.00	16691761.36	1575000.00	205838.07	0.00	1780838.07	14910923.29	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
e0fdace1-ae0e-4aac-8c94-fcbd78f098cc	951f937f-2724-4cf5-9b4f-7528f736d782	628e25c8-8d51-4e98-8b22-3fad1526745b	6	2026	15000000.00	85227.27	15000000.00	447443.17	1000000.00	500000.00	16947443.17	1575000.00	218622.16	0.00	1793622.16	15153821.01	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
59c34cf3-8c43-449f-ab01-609103cae365	35337165-e0d0-4dd1-9c67-cc48180363af	ef7b3ee1-5404-467d-940a-dd0a312dc25d	6	2026	15000000.00	85227.27	15000000.00	511363.62	1000000.00	500000.00	17011363.62	1575000.00	221818.18	0.00	1796818.18	15214545.44	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
bd49c33d-9054-4995-8910-b06497d8933c	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	1322956c-10b8-44e1-985c-5fec39a8bfe8	6	2026	15000000.00	85227.27	15000000.00	191761.36	1000000.00	500000.00	16691761.36	1575000.00	205838.07	0.00	1780838.07	14910923.29	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
7051f0c6-5249-417b-9505-f1088a2ab62d	9fbc67a0-b671-479c-9b46-3076df068741	40b21b60-9978-4c33-a420-bf3a775a532d	6	2026	15000000.00	85227.27	15000000.00	191761.36	1000000.00	500000.00	16691761.36	1575000.00	205838.07	0.00	1780838.07	14910923.29	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
e53638b2-4425-4531-ae88-362bcacc3ea9	cf26d867-49f1-4c12-b35b-c79bfb2884fc	e800819a-800e-46fc-b1c0-ab332ea5b20c	6	2026	15000000.00	85227.27	15000000.00	191761.36	1000000.00	500000.00	16691761.36	1575000.00	205838.07	0.00	1780838.07	14910923.29	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
12165243-e516-4365-812a-7cf232737865	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	2f2bbc9c-c4e9-471b-acb5-43e11f7c7b7a	6	2026	25000000.00	142045.45	25000000.00	532670.44	1000000.00	500000.00	27032670.44	2625000.00	1261150.57	0.00	3886150.57	23146519.87	PAID	\N	2026-06-26 14:00:00+07	2026-06-27 16:00:00+07	2026-06-28 10:00:00+07	2026-06-26 14:00:00	2026-06-26 14:00:00
9002ba86-dbef-45a9-a2d5-9c3b4cfef518	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	305fbfd7-0624-4299-891e-112f1ed7f97e	7	2026	195000000.00	1059782.61	195000000.00	3974184.79	1000000.00	0.00	199974184.79	20475000.00	49124714.68	0.00	69599714.68	130374470.11	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
1ac88045-9510-4285-ac18-06b147c062b0	5934b552-2406-4a70-b69b-f0abec6bdd28	0a28674e-8667-44c5-b065-7b00b1159ec4	7	2026	65000000.00	353260.87	65000000.00	2119565.22	1000000.00	0.00	68119565.22	6825000.00	9323641.30	0.00	16148641.30	51970923.92	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
63008711-e893-4bb4-a4ab-7d5b425ff5e2	6b39462f-1134-4e9a-9a06-f2b3687940b7	77b0d151-bfa1-49cb-9014-96ed10db4e6b	7	2026	50000000.00	271739.13	50000000.00	611413.04	1000000.00	0.00	51611413.04	5250000.00	5590353.26	0.00	10840353.26	40771059.78	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
6265862f-e3bc-4f09-9af1-7106487b74e9	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	3214f4c6-b903-431b-8908-e6f3a1884d15	7	2026	30000000.00	163043.48	30000000.00	733695.66	1000000.00	0.00	31733695.66	3150000.00	1887554.35	0.00	5037554.35	26696141.31	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
ebf94aac-dd5c-454e-95d2-38e6ea06a725	c6322771-714d-4d31-a732-47f86ac8465e	197d78f0-5b9e-4409-98af-9a4b7b4ba71a	7	2026	30000000.00	163043.48	30000000.00	366847.83	1000000.00	0.00	31366847.83	3150000.00	1832527.17	0.00	4982527.17	26384320.66	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
cf83cc7d-4461-4eba-8f89-5aa20fdf27ab	fca9aa46-b141-415f-ab4c-9f336bdfd46e	c8233dbf-910a-414a-8be3-b4595003602b	7	2026	30000000.00	163043.48	30000000.00	733695.66	1000000.00	0.00	31733695.66	3150000.00	1887554.35	0.00	5037554.35	26696141.31	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
d8fed02c-4d9d-47bd-aa63-5716a9b7073a	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	f7abe3e5-3289-4aee-90a0-d61ce26742b2	7	2026	35000000.00	190217.39	35000000.00	1283967.38	1000000.00	0.00	37283967.38	3675000.00	2871793.48	0.00	6546793.48	30737173.90	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
f94de67f-155d-48c2-8063-c4066a190f86	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	3d9f34be-c6fe-4017-910f-05e73aba6276	7	2026	28000000.00	152173.91	28000000.00	1141304.33	1000000.00	0.00	30141304.33	2940000.00	1680195.65	0.00	4620195.65	25521108.68	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
cbcbb397-d03f-4de2-87e9-a7378af5d78e	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	5d23ac7f-0bf2-4bad-843e-a59acb5e3bcf	7	2026	35000000.00	190217.39	35000000.00	998641.30	1000000.00	0.00	36998641.30	3675000.00	2814728.26	0.00	6489728.26	30508913.04	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
d79b25d2-97fd-458f-b2ea-6a4236735129	d1f7cf77-4784-4b35-8d12-f2833e3bb066	42112cc7-4b33-4c7b-ac90-cb852fa6d8d0	7	2026	15000000.00	81521.74	15000000.00	489130.44	1000000.00	0.00	16489130.44	1575000.00	195706.52	0.00	1770706.52	14718423.92	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
5adc46bb-ce25-4a11-a3ef-fcd570f683de	951f937f-2724-4cf5-9b4f-7528f736d782	c95bdd4d-05c1-4b11-91e8-b3bcf62a0373	7	2026	15000000.00	81521.74	15000000.00	489130.44	1000000.00	0.00	16489130.44	1575000.00	195706.52	0.00	1770706.52	14718423.92	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
7de18722-218a-485b-bc1e-581ec8a62c11	35337165-e0d0-4dd1-9c67-cc48180363af	28a837e9-9668-4279-8caf-719c5c6c4394	7	2026	15000000.00	81521.74	15000000.00	611413.05	1000000.00	0.00	16611413.05	1575000.00	201820.65	0.00	1776820.65	14834592.40	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
ef0d3665-513a-46f9-8c8c-27bba4c40d90	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	95c56641-7a4e-46f5-82b4-2eb8a0f3d3d6	7	2026	15000000.00	81521.74	15000000.00	183423.92	1000000.00	0.00	16183423.92	1575000.00	180421.20	0.00	1755421.20	14428002.72	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
983cf1f9-e886-4944-a506-1a0970afeec3	9fbc67a0-b671-479c-9b46-3076df068741	53180f72-29fa-4b7a-91ef-ff91222501f5	7	2026	15000000.00	81521.74	15000000.00	611413.05	1000000.00	0.00	16611413.05	1575000.00	201820.65	0.00	1776820.65	14834592.40	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
395c0cd8-3e06-4f9a-aa1e-0db67b9df2a7	cf26d867-49f1-4c12-b35b-c79bfb2884fc	3c1b434e-18ba-4f67-aa8b-d1cb592b6d77	7	2026	15000000.00	81521.74	15000000.00	489130.44	1000000.00	0.00	16489130.44	1575000.00	195706.52	0.00	1770706.52	14718423.92	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
294cb31f-16c7-4bb6-a5b5-a9f351035130	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	d19fc0bb-b898-435d-b07c-2418f6c23101	7	2026	25000000.00	135869.57	25000000.00	917119.60	1000000.00	0.00	26917119.60	2625000.00	1243817.94	0.00	3868817.94	23048301.66	PAID	\N	2026-07-26 14:00:00+07	2026-07-27 16:00:00+07	2026-07-28 10:00:00+07	2026-07-26 14:00:00	2026-07-26 14:00:00
8ac96670-ad57-4bef-9f2f-9d597ad37470	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	1f0636e9-1a9d-49a5-a08d-4d020197cea0	8	2026	195000000.00	1160714.29	195000000.00	6964285.74	1000000.00	0.00	202964285.74	20475000.00	50171250.01	0.00	70646250.01	132318035.73	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
182c11e6-6eab-4be5-b8ee-a8871d90e79c	5934b552-2406-4a70-b69b-f0abec6bdd28	d3f45f93-30b0-408b-881e-38c8f87c451e	8	2026	65000000.00	386904.76	65000000.00	2611607.13	1000000.00	0.00	68611607.13	6825000.00	9446651.78	0.00	16271651.78	52339955.35	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
21ccc75d-e347-40d3-ab37-b3381971ea67	6b39462f-1134-4e9a-9a06-f2b3687940b7	f7198862-c381-40fe-b5e9-eb6b2f4b2caf	8	2026	50000000.00	297619.05	50000000.00	669642.86	1000000.00	0.00	51669642.86	5250000.00	5604910.71	0.00	10854910.71	40814732.15	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
1b79132b-d935-410c-a2c9-a71cdaf7398a	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	bb999c00-ed3e-4720-a575-c5810283673d	8	2026	30000000.00	178571.43	30000000.00	1071428.58	1000000.00	0.00	32071428.58	3150000.00	1938214.29	0.00	5088214.29	26983214.29	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
3d6eeef7-ec42-40c7-9d43-b15b2703c99e	c6322771-714d-4d31-a732-47f86ac8465e	c025be56-fa67-44fa-9818-d07c34e5f309	8	2026	30000000.00	178571.43	30000000.00	803571.44	1000000.00	0.00	31803571.44	3150000.00	1898035.72	0.00	5048035.72	26755535.72	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
0c5aa3a4-0a79-401b-a6c5-2508aa29ba2f	fca9aa46-b141-415f-ab4c-9f336bdfd46e	99916a4f-6937-4575-a4a5-6bf6ff7d8e8f	8	2026	30000000.00	178571.43	30000000.00	1339285.73	1000000.00	0.00	32339285.73	3150000.00	1987857.15	0.00	5137857.15	27201428.58	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
aa898cf5-0deb-4525-b4d5-39d6b43c7259	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	044d98cf-b2e4-4aa3-9c1c-6b3545076d1b	8	2026	35000000.00	208333.33	35000000.00	1406249.98	1000000.00	0.00	37406249.98	3675000.00	2896250.00	0.00	6571250.00	30834999.98	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
199bab42-5175-4c28-aa3b-8133da4a1641	1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	47e82509-e8bd-452b-8430-0ae6e6bd0b41	8	2026	28000000.00	166666.67	28000000.00	875000.02	1000000.00	0.00	29875000.02	2940000.00	1640250.00	0.00	4580250.00	25294750.02	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
d73d4593-6016-445d-9c6c-32e2caab21ec	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	7e39afba-27d4-4bf4-99ec-f6f8f7f229dd	8	2026	35000000.00	208333.33	35000000.00	624999.99	1000000.00	0.00	36624999.99	3675000.00	2740000.00	0.00	6415000.00	30209999.99	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
cc390bc8-74ea-417f-9c18-db3c2d154662	d1f7cf77-4784-4b35-8d12-f2833e3bb066	aea49108-8198-40ae-b664-5f9a67df5283	8	2026	15000000.00	89285.71	15000000.00	200892.85	1000000.00	0.00	16200892.85	1575000.00	181294.64	0.00	1756294.64	14444598.21	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
071903a3-4f58-449e-bab5-531e329dbc10	951f937f-2724-4cf5-9b4f-7528f736d782	ed4f48d2-6d7a-4915-a3fa-cadd3eeb545a	8	2026	15000000.00	89285.71	15000000.00	200892.85	1000000.00	0.00	16200892.85	1575000.00	181294.64	0.00	1756294.64	14444598.21	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
fd1f34f4-c7e6-4a21-b439-e7ab9b0726ab	35337165-e0d0-4dd1-9c67-cc48180363af	81819ef1-4b59-43e5-b818-3d176425398b	8	2026	15000000.00	89285.71	15000000.00	267857.13	1000000.00	0.00	16267857.13	1575000.00	184642.86	0.00	1759642.86	14508214.27	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
4f23aec2-9231-4790-abec-e6dfdb68fc2d	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	480689f8-1d1f-4ce4-b470-ff152361e8bc	8	2026	15000000.00	89285.71	15000000.00	602678.54	1000000.00	0.00	16602678.54	1575000.00	201383.93	0.00	1776383.93	14826294.61	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
e68b12ae-5cdb-42c8-8ba2-760187ba5fe5	9fbc67a0-b671-479c-9b46-3076df068741	d76e7b81-9d73-4be6-9523-7b984b8fe98b	8	2026	15000000.00	89285.71	15000000.00	334821.41	1000000.00	0.00	16334821.41	1575000.00	187991.07	0.00	1762991.07	14571830.34	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
d9ae9914-9823-4b10-be88-ce6c5580b182	cf26d867-49f1-4c12-b35b-c79bfb2884fc	802e06d2-b7ab-4e36-abcd-084cc3b73e7f	8	2026	15000000.00	89285.71	15000000.00	535714.26	1000000.00	0.00	16535714.26	1575000.00	198035.71	0.00	1773035.71	14762678.55	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
4f156a9c-1ff7-4c84-ab00-f2593da7c79a	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	2153268e-2510-471b-afc5-d86f7362af1a	8	2026	25000000.00	148809.52	25000000.00	446428.56	1000000.00	0.00	26446428.56	2625000.00	1173214.28	0.00	3798214.28	22648214.28	APPROVED	\N	2026-08-26 14:00:00+07	2026-08-27 16:00:00+07	\N	2026-08-26 14:00:00	2026-08-26 14:00:00
\.


--
-- Data for Name: pending_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pending_users (pending_id, first_name, last_name, gender, birth_date, personal_email, phone_number, citizen_id, place_of_birth, department_id, job_id, shift_id, base_salary, contract_type, contract_start_date, contract_end_date, status, rejection_reason, created_by, created_at, updated_at) FROM stdin;
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
b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e	25000000	\N	t	MONTHLY	2024-01-01	22	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d
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
a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	19036888999018	Techcombank
\.


--
-- Data for Name: user_contracts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_contracts (user_id, contract_end_date, contract_start_date, contract_type, contract_id, is_active) FROM stdin;
5934b552-2406-4a70-b69b-f0abec6bdd28	\N	2020-03-01	Indefinite	8b0cd135-32fe-42f8-b0b3-d9e8a529a62c	t
6b39462f-1134-4e9a-9a06-f2b3687940b7	\N	2020-03-31	Indefinite	2446b2be-16ec-48ad-8cb2-7c92271a28b7	t
ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	\N	2020-04-30	Indefinite	3520fad0-98d6-4daf-8aeb-ad4fe0ef3f78	t
c6322771-714d-4d31-a732-47f86ac8465e	\N	2020-05-30	Indefinite	6248c13f-c1e5-4735-872a-1b99e7729219	t
fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N	2020-06-29	Indefinite	39db5e77-1708-488f-a9d6-1b83d298a93d	t
a3214f8e-94d1-4f9e-80c7-bd66dd570a78	\N	2020-07-29	Indefinite	8c982565-c3b1-44ba-906d-426b1c901654	t
1bc8ec1d-c6c4-42c8-a905-81bdb3d20bb1	\N	2020-08-28	Indefinite	9ead9e03-a80e-47f8-8d6a-72216191983a	t
cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N	2020-09-27	Indefinite	3c76715b-58f5-4364-8372-48857fac928d	t
d1f7cf77-4784-4b35-8d12-f2833e3bb066	2027-02-21	2026-02-21	Fixed-term	62bab603-2f6e-4d37-af1b-15794cbf0c61	t
951f937f-2724-4cf5-9b4f-7528f736d782	2027-03-23	2026-03-23	Fixed-term	506d495a-b2bf-481b-b7a4-751ae982bb2e	t
35337165-e0d0-4dd1-9c67-cc48180363af	2027-04-22	2026-04-22	Fixed-term	d40d308b-a5c1-4ff8-b788-429ff96f328e	t
1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	2027-05-22	2026-05-22	Fixed-term	7f8200d4-3fff-4b8e-893c-35733fed2f01	t
9fbc67a0-b671-479c-9b46-3076df068741	2027-06-21	2026-06-21	Fixed-term	85d5f6ab-1fe0-4e8b-9743-c4010db94dab	t
cf26d867-49f1-4c12-b35b-c79bfb2884fc	2027-07-21	2026-07-21	Fixed-term	ca7965f3-6112-4f5e-af92-bcf5932b9527	t
1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	2029-10-01	2026-10-01	Fixed-term	3066b231-26a4-42e4-9892-6b00ee50c910	t
a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N	2024-01-01	Indefinite	c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f	t
\.


--
-- Data for Name: user_permission_grants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_permission_grants (permission, user_id, granted_at, granted_by) FROM stdin;
ORG_MANAGE	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	2026-09-28 16:07:50.494072	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d
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
a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	079095012345	Nguy?n Van A	0909999888	Single	Vietnamese	sysadmin.personal@gmail.com	0901234567	TP. H? Ch¡ Minh	SI0790950123	2024-01-01	8392019284
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_sessions (session_id, created_at, device_id, meta_data, revoked, token, user_id, last_active_at) FROM stdin;
577f09dd-139e-4199-b66a-653139b09e2f	2026-09-24 10:14:39.474807+07	91f1e0f9-221e-41eb-9332-0b8ff31dacbf	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	SnLa3xfE/RRl5aFHdji6yIZIuvelm9ofUWAU+bQXrgg=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
a4560b12-c404-4074-b83a-bbe5d987b4f4	2026-09-14 15:09:56.397533+07	208cf28f-ec92-4e23-9b69-35b4a9dfd539	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/7.56.1"}	t	0kvxL1GW/L5s0pIOtmnaedOinFtXGUSL/UzoKk7X8JY=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
2e62282b-a578-4133-b596-30ce60ead34f	2026-09-23 11:45:34.283947+07	1eeff7f3-3dd3-45f4-9a8e-bd75cfe181b6	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	tFJi+qKLq2/7GZ5QVZVBSsT+c5z73t/7eCpE9s1qr9s=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
e67f571d-9a13-448b-8845-9959aca0ff0d	2026-09-24 09:15:43.760557+07	0a775fed-af6f-4b5c-9329-8c044aec954d	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	39rDed9cN6rYw+b2rISkbx/f07/bC3m5K7lSHWL8T4U=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
d62915b1-f5ec-4a40-b0dc-ba9b87ee4352	2026-09-26 20:22:30.820062+07	84d9185e-0f0d-48b7-99db-3d6660198890	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Chrome", "country": "LocalHost", "deviceOS": "Windows NT ??", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"}	f	WdWFIjnZX89fvawu68/82uU2dNj6Zrt0rzPJyBXgPfs=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
71e6cc83-4dc9-4fb9-8a4f-573b4e7a1722	2026-09-24 09:31:14.065192+07	3d429e43-f5c9-456f-937f-82d358739e98	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	iHLq9D4KW52anAN/Q2SZxMR5z5y6pSuGYBjJ0t1yUSk=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
ae36aea6-b6f6-4d64-84c6-50b9f13a5b05	2026-09-22 14:45:53.609175+07	b355ac6c-5333-4c26-b5a6-89fd0ce847cf	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	4DncbK9Mbj/Ymhiv1WBPUr/taL8DGx06yPJuUQOYCFs=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
db850c5e-e1ef-471f-b4f8-123031ad6faa	2026-09-26 11:06:18.200863+07	2fabdcf9-292f-49a1-877f-874765ef5471	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-urllib", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown", "userAgentRaw": "Python-urllib/3.11"}	t	TiROb87NKGqw7xkpzM/5URoBC7e6xUnZ6WyuUQAnaXA=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
4c4e948a-1f6f-48d6-bb8d-c9b801928f58	2026-09-23 14:53:42.404138+07	d4e6c9cf-4697-48a1-8963-37975e31937f	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	lo5be9QaRMmMeADgdM2l6HR1PVFzyJRUDX46utyoRmo=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
be7080cb-1983-494e-86a3-bbc48e417036	2026-09-23 11:05:14.629135+07	cd8b8b2a-dbe0-4a53-84f8-e9507fb54466	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	2++tLZqItlemA6ALWEJ9UXx7WkxBFB5NSe75JwZ0SA4=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
d6a45c84-177b-45e2-a965-5dcf38c8fa41	2026-09-26 20:29:08.598256+07	84d9185e-0f0d-48b7-99db-3d6660198890	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Chrome", "country": "LocalHost", "deviceOS": "Windows NT ??", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"}	t	NjARp3t4CBoaxcGWUmaU1arOg6fB27U39Sp2FENR/L4=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
3bb4c098-1b8b-458e-88e4-9bc4aaa9b940	2026-09-26 16:52:49.486849+07	490117e9-614a-4cf3-b14d-3ddcbf0479a1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	B0a5HPFusAzk1FzvEFF/ZAeEujrBRxt+K9xWaG2fG58=	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N
340c10a9-c762-4f98-a156-ad760d544f2c	2026-09-26 10:35:39.436806+07	9155b1cf-44c5-41d1-be2a-ce8f4f2e9f15	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	r3Vv7bZeJSyecmKQF8qxR/2JFqqOdya9tpkkyd8JbRc=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
9976a9f6-d268-4b75-aa7b-fab56c3967f4	2026-09-26 10:41:26.491691+07	ff077b2f-d2b8-4c2b-8855-8a037ae8496d	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	t+l5+o1QMhr7uiVFGwxDySzn0HnoxN6gcq8GeotxUwo=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
a2933aff-6baf-46b4-b53f-b4fa81d7c4bc	2026-09-24 10:22:00.804415+07	f36e94f6-1827-4478-a8e5-3991785a53b2	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	vWfvIeiOq8DRELUxUOftEYk9sUEPyUDbSMCg9P/EnG4=	35337165-e0d0-4dd1-9c67-cc48180363af	\N
cb3b553b-c902-4360-be4c-1f1664d04d9c	2026-09-24 10:18:50.182573+07	ff33f310-43d3-4639-992c-8f81e65780b5	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	f	jih+Lo3DKKxyWFQfd5z4dhkCJ7ys8DGKiMNgXeojCCQ=	d1f7cf77-4784-4b35-8d12-f2833e3bb066	\N
afc5ffa1-c812-4bd1-95a4-dc3a56f32f25	2026-09-24 10:32:08.663961+07	a24256ba-baf5-4acd-9f08-aa4ab0cd7a71	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	f	zvqsn4SX5bXcQ/oucdD9YuZ82j4Qf5/Jwi2mEMHrFUw=	d1f7cf77-4784-4b35-8d12-f2833e3bb066	\N
45c15bf9-5479-447e-ade5-6807750a4268	2026-09-24 09:59:05.546995+07	33092490-1d0a-4ddb-a923-3e532098a11b	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	gKAPDIlUazz4QgKpCo4AonidnQmtyksO9R+qmaPHTI0=	35337165-e0d0-4dd1-9c67-cc48180363af	\N
6e12da6f-91f4-4db0-a883-a5e3d2e24c5a	2026-09-24 10:33:39.217869+07	b416dab2-70e3-4711-95c5-95ae29822411	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	f	6SgTj9I8yOw6+T6FEV8FvzjfkJzAihH1hXlcoGw1oQQ=	d1f7cf77-4784-4b35-8d12-f2833e3bb066	\N
12e803a8-da85-4110-ab23-dd8e08b0104d	2026-09-24 10:41:37.212826+07	9771bce1-5d4f-4c71-b4e7-99b554dd2013	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	f	piiquZ98+C20Vh6rAI2igh5DC3iD49HVFJTF4hJ/wkA=	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	\N
d09bba7d-fdec-48c4-a424-7bb1a3739b21	2026-09-24 15:02:31.105654+07	3b849daa-3a77-495f-8e05-1b0b3c62fc14	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	f	7kdxqfMQMztnKBwrWTN5FJR/ZydZBpjtlhrxn2fSCUk=	ffc3e6f3-20d2-46d9-9c6c-a853aef2e7aa	\N
e60caa50-3c81-425c-bf56-738c2a5b042e	2026-09-26 19:12:35.837215+07	84d9185e-0f0d-48b7-99db-3d6660198890	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Chrome", "country": "LocalHost", "deviceOS": "Windows NT ??", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"}	f	VeucOS/mkmpHfA+/s31gVFDDNcxR6LVfmZk8cOsRLLw=	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	\N
e0cd62d0-d808-4ca9-8ced-eda9c8da1e87	2026-09-25 16:45:55.239574+07	c2842c06-8d1b-476d-ba4b-874b246c41c5	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	iFEWABZx1ZeYYXnsUui+InwE7dUfq7bP/xAuUz2Ce4I=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
4982e104-1ec1-464c-a83d-fb5a28ea9e03	2026-09-25 16:51:44.16746+07	ceedfc4a-3b0c-42b4-9824-97317960f747	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	QN/9T2isrPeAy1/k6LoGbpMotbpacdV9LfsqAS4RdNU=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
8d53b7a4-3d88-4467-9f0e-3ee531f587bf	2026-09-25 16:51:15.978652+07	8b19b63f-fad5-4257-8957-8fe7bee188f9	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	2AHiK6UW7WZfjAH+qhnSImyGoYIbXkhQta/SjTh8nGE=	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N
c3b9e87a-00cc-49f6-9d1f-183893d9724b	2026-09-25 17:02:10.149873+07	58ad04fe-e2e8-4003-b77b-3b3d0e1bb285	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	2sM67cs3qI8J8eg68tRYUZI+iu7EFJMmUgZKJuz88Og=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
38f18cc8-0422-480a-8287-5b805c96bf0f	2026-09-25 17:02:26.402341+07	559d7a9e-8335-4290-9bff-aa163b91d8c4	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	1791AnouiZNxe76Gu8zxp/zBoTrOm2QbE+/TATK3A80=	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N
fe1d97a5-c46b-4a57-a93c-31bd22e0ab73	2026-09-26 10:43:13.233782+07	79e82360-f36f-45df-a248-8449d2e86e5c	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	LQyn61TS/axu3MjCkH7UvXyddazjVn6O3LzdCI2jmds=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
1daf3e4f-6a7a-44b7-913d-a0432fac3cf4	2026-09-25 17:01:37.57777+07	96e421e5-9eef-442b-8f75-69757e06d87e	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	0yHDAnh8DBGe2nImpaLw2YZJsqSGBh5hXlC1IOFtnkU=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
f7c599c1-20b6-48ff-b842-268c12fdf351	2026-09-25 16:55:31.312941+07	467cc46b-d118-4cb4-b5fd-5994bdc9bdba	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	BYrgLDANNLHhP2aQRhQUv2srBczxO8PsALrvjQac1KU=	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N
8d017d22-f443-4cda-8830-7307e7cfe635	2026-09-25 16:51:30.122491+07	9f2d5131-05ac-4708-b7aa-e3ccdfbd14af	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	6CDN4hlWXt0zeelAN9fyAWWHuPLV0/ZFljUi0OYtG2s=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
c6938dc3-0f0b-4b43-90c1-9c6edad1400f	2026-09-26 11:06:22.462274+07	a1322a99-8647-4604-a0ff-e3fd636d8001	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-urllib", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown", "userAgentRaw": "Python-urllib/3.11"}	t	4aMb24otWM0iO8AeORxQufmXrQjNnuFCUQgmdnErSaY=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
70d71092-0846-4c33-a985-217ca8c9e534	2026-09-26 10:43:45.292606+07	3ac71777-e2ce-4cf1-9acf-f360aa5c806c	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	IhHc90WJCFElm/d1Xv+pP3ab2ahtI5T2Wg0K8tl7XU0=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
3b631f84-ee3b-41bd-9308-5a4e2e34002a	2026-09-24 10:33:47.811465+07	38d3a69c-dd13-4fe3-888f-9770492e7717	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	YMG/E2qjfP1btn1znZCbsJbANGZOcuUsYLhK4igTIkA=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
8a4dcc41-4119-4699-8d14-a1a2b7734193	2026-09-25 17:02:40.616876+07	f764bd36-4a7d-44b4-8584-a807b5dade9a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	AmYtOyF688JSYhsY6hHNDN4RcOGv4HTkeV671KasFpY=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
97f6a721-9309-4cca-aec9-f9622f366a4f	2026-09-26 17:46:13.283141+07	490117e9-614a-4cf3-b14d-3ddcbf0479a1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	IGQ66/hehwrI/xmVWDDju0T+CCqXGdKbrNAclzbnsCo=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
536094bf-3ac0-4df8-bb1d-6d61b1112f53	2026-09-26 20:28:25.636263+07	84d9185e-0f0d-48b7-99db-3d6660198890	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Chrome", "country": "LocalHost", "deviceOS": "Windows NT ??", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"}	t	C4XJMo/3DwlD623DL4SJFUD/yi1P0O2VvetnU8EuReg=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
6414cd83-71d0-4dcd-8b80-06648c6b0d1d	2026-09-30 09:17:17.363414+07	60385fa2-b3b1-4c21-b227-531cfee4405a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0"}	t	eCqGUZjRYe4DQac0BgSsny3oJJ4+aQ6vUbB00/jy6OM=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
bde50a8f-b567-42e3-8731-aeb873f47e08	2026-09-26 20:28:57.453047+07	84d9185e-0f0d-48b7-99db-3d6660198890	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Chrome", "country": "LocalHost", "deviceOS": "Windows NT ??", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"}	t	p9cf5g+gxZYcqibYceYe2bvj5ajzOMm8xztsrmc54kQ=	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N
6ddeb685-64fe-40b3-bee7-38f11b2c650a	2026-09-26 20:25:00.415806+07	f0ee6218-1f19-461f-b6b6-f38d015354af	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	YXDWSfv0V0XpAG3Y2D0vI4zIk/H2YKugQIonbZmLbSQ=	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N
1e3db761-cfbc-4faa-ab7b-87aa50a82532	2026-09-28 16:05:39.929386+07	60385fa2-b3b1-4c21-b227-531cfee4405a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0"}	t	3a5B6m2KatwbezrB2u/LbVjEZGs9B43wwqMoTIBWcvA=	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	\N
3bf06a94-eaa6-4a5b-bfc5-d78719a8c171	2026-09-26 11:06:28.728193+07	ee598b40-3125-460c-aa8d-6c7318f5700b	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-urllib", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown", "userAgentRaw": "Python-urllib/3.11"}	t	KT3uozgxBLzlxXR9XcDXxA6T1jdlgbOkeeZdf+s9/Ds=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
0cd499c0-28f9-4526-9080-e37c295dc294	2026-09-26 20:24:21.402469+07	f0ee6218-1f19-461f-b6b6-f38d015354af	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	5uMIQCAkNqq+mjJQ/ADbimNrB6Y8nXqBnofJ4xSFiBk=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
c3a6183f-a78e-4a43-a816-590aa6642098	2026-09-26 17:46:20.701609+07	490117e9-614a-4cf3-b14d-3ddcbf0479a1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	QvQlHTIrjCGB7Ep/OPGm/kyRTzEuv6gwJ9S2ZdOXCJY=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
11b557c6-c939-4371-bb36-b6649b8441bb	2026-09-25 17:06:29.056193+07	ca17b30e-d385-43ef-b0eb-a07018bcc399	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	sTgyhdEJnBkqWZQ1wjpy6VZ8DctbwHIImLQJz0BZxSw=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
6a15496b-9fe0-4fdb-9d02-17b99a87bf9d	2026-09-26 09:17:14.354436+07	206eff9c-78e0-49c1-80d1-80bcca9e5fd0	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	h/yE8HhPEVIBYjfYvmkaJ4XXS6qvhosx5FRuFYj33ts=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
8a972df9-ae94-4760-8da3-86914f4e1ed5	2026-09-25 17:02:55.008604+07	3bd9f0fc-6b2a-4cbd-a58c-bc890df0f521	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	65x/e3ulNzjtQE50giSaD1vR8RuUvLJyyTYPiJaz1eI=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
b550d82f-181a-49b5-a7aa-d4520bd20725	2026-09-26 11:06:32.824678+07	640163ca-36b5-4d58-93db-394d3a12eb20	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-urllib", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown", "userAgentRaw": "Python-urllib/3.11"}	t	GfJMllcLFiSS+xEc7N/sNhhMtTecUyvBw8mXeiVXbkQ=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
a469079c-eb58-4a73-88e9-8501d23ab688	2026-09-26 18:10:00.021476+07	6bb85b4c-5a30-44b3-9feb-ff452e3ac8c3	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Curl", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "curl/8.21.0"}	t	eSyBk/J1UG4pYFpdppFRh95cUCazhL2e5WGfBrt2IRk=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
1d09bf86-26cb-495b-a84c-418012bfbce7	2026-09-26 18:09:33.697101+07	a3f35224-2ada-4062-be9d-25261d7773d3	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "HRM-Test", "country": "LocalHost", "deviceOS": "Unknown ??", "deviceType": "Unknown", "userAgentRaw": "Mozilla/5.0 HRM-Test/1.0"}	f	Mwjunnss8zFgYfk2WmwromiW1nD86ClWgrnQA6Wex+c=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
99ea8c29-4deb-4a6a-a00d-2401d19f52f6	2026-09-26 18:09:59.888475+07	c4b1ab3b-498c-47ef-91db-8d18cfdcef9a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Curl", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "curl/8.21.0"}	t	UcnvEH59GjkborLQWQJ8UcWk5osKpq6icfThgWWndLA=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
7b0572f4-b0f2-4822-a090-1abc328f02bc	2026-09-26 18:10:00.115476+07	f738e05d-b252-4af5-9d3d-e56a454231a6	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Curl", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "curl/8.21.0"}	f	j8CV8lt1dUSIibtKhDheod+Edx+DXcryfYzqnx6br5Y=	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	\N
9051b9a5-6920-49a4-88e0-005e26cca8d9	2026-09-26 18:10:00.215474+07	d24d04ef-241f-44c0-a2a0-276e2d4c1c9c	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Curl", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "curl/8.21.0"}	f	3Ek1qXj/IZYnel7A11zVtTMYHVn+Bz9NhlqkO9CFqFA=	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	\N
bd691077-adee-40da-8663-0834c3f2e026	2026-09-26 18:10:15.724379+07	a48c405f-01f2-46b5-aa4a-5f82e304e77d	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Curl", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "curl/8.21.0"}	f	JyCaJsttkXhWxt4Ej26kVZVPWHzuMuJblC0zyDRjnzQ=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
aaf2818c-bec6-4a81-a381-d4d3be00eebf	2026-09-26 10:46:27.901978+07	06893342-a204-458e-a1e2-bb7247f0ea42	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	WGPl7jVBObSQnaIWMpCIR9GZD6MbEQCF6RrO3rdQeDE=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
8108de4d-0174-46e2-9946-40e130b0dd5e	2026-09-26 10:46:56.777119+07	efc9fbc4-f5b0-4d18-a2fc-c314e1f5d1b8	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	jA3sXZu8ix0ZjI29HZr+PRnI/2VKCh+Ex3Bz0LqVw0E=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
9684ae4b-2d5a-46bc-973c-2572c9f1466d	2026-09-28 16:07:10.809632+07	60385fa2-b3b1-4c21-b227-531cfee4405a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0"}	t	1AhmiJFKpdxxJ1BCwUcYWCmFiQsqbwz8cOR5WzVO4aA=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
b17ff9b8-317e-44d5-bb80-ca06f664ee98	2026-09-26 20:30:04.697143+07	89d27bcc-ff07-4d0c-b506-54cf2e1e9373	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	96q6Ehq7VRv0rCjRLXv7gpQ2yW3fvIP07DCHJNXGxIQ=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
02a1d4e8-c4f2-4162-862d-ec5a25086d89	2026-09-25 17:29:24.048229+07	313d59eb-7e26-446e-a596-6b07f02f83a5	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Safari", "country": "LocalHost", "deviceOS": "iOS 16.5", "deviceType": "Phone", "userAgentRaw": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"}	t	eT5lPUhnLEcz7awIqP5xBNbzCpdJOs3yEl/98Odosh0=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
2fa5af85-f881-48df-8104-ca882e48f3b5	2026-09-25 17:06:02.103947+07	47b932a3-3e18-4888-a1a5-98246135ef28	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	KPQze1080NXAsWctvPkSSdzJy6n2Smpp84CTgkrZ0OU=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
038a03ed-96e4-4781-b116-5539bcb3971e	2026-09-25 17:30:32.497966+07	aa9ca84e-efb5-4296-87e6-7f67f7d3760e	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Safari", "country": "LocalHost", "deviceOS": "iOS 16.5", "deviceType": "Phone", "userAgentRaw": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"}	t	Bi7SZMQh55bZoVwFaYsniETyLfwpZWXwNCou60JlWt4=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
ddb8f059-4304-48dd-8a74-843b1c43f0d4	2026-09-30 10:44:21.666472+07	60385fa2-b3b1-4c21-b227-531cfee4405a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0"}	t	TCpU6GIWkYycEvk0XXcxVFhd2DrHQFQ5Uwie4s0oFvo=	35337165-e0d0-4dd1-9c67-cc48180363af	\N
8fb0eca3-ec68-4357-be47-23e0e6b8bc3e	2026-09-25 17:32:48.292484+07	97c0840b-2bfe-4878-9e4c-bb322202ff31	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Safari", "country": "LocalHost", "deviceOS": "iOS 16.5", "deviceType": "Phone", "userAgentRaw": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"}	t	/M4G3eVfT5MsGGmSkhGqmCyiFApYf36OOOL4E1mS9aY=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
801dc7e7-8ee0-4c18-a3dc-9e4507fca195	2026-09-25 17:29:10.202472+07	d45a0999-2154-4fa3-908c-eb5b88d04b09	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Safari", "country": "LocalHost", "deviceOS": "iOS 16.5", "deviceType": "Phone", "userAgentRaw": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"}	t	vZ5T1iaZHHigteKceK2BGVrK+W9Ne9iU6k9H7WkwLvc=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
1d64ba51-b705-4327-8342-c5767682683a	2026-09-25 18:21:18.895135+07	300f3638-bdd7-4fcc-ad6b-3eca5afcb442	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	WM2a+gVzU1XnUexGZC6x4bBVif55hyZv65GwQKghVyE=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
f23a37f7-dbe1-4547-b492-126077cdf998	2026-09-26 11:11:19.205747+07	0743e83f-449a-4bec-8b6d-4e04eaf82b91	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	HCrSeZcRJifu4KBwtaE2MpxS/I/CIuO2QeYFnM+sRZQ=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
cea4ca9f-d7ba-4523-afe5-691676594942	2026-09-25 17:46:53.673744+07	e72a1aa9-982c-4625-ad6a-23bf99ec1d05	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": null}	t	Lq6b3chkxotrnGZd+WaAINJJni2dO/CLXIvGm/anbno=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
b10852fc-6325-4d4c-ad61-716272acdc1c	2026-09-25 17:51:13.129755+07	88f98e9a-8679-45fa-927e-fa9376b32474	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	npo6Ns4gEhXBARHQmk3CIlEOJC6Ev4p8L7WD2HacLTM=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
d1164428-5a93-45c2-9f5f-c7732e6d835e	2026-09-25 18:28:54.268517+07	aae76b32-b345-464d-91d6-b173fe725fc1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	AIEAnqdykTkOCfyJ4fCDHGQu8s93acW/CDXtKwr1gBk=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
ee410a36-1252-4917-a2a0-2b9547955551	2026-09-30 10:44:27.549299+07	60385fa2-b3b1-4c21-b227-531cfee4405a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0"}	t	DDRPXFNA3abC8dm39R2FtO7asSiMOB94hFK9dwizR5E=	cb0bf52b-924d-4a02-bcde-af3cb2a371ff	\N
a8bc54b3-4c49-4555-9b3f-8143b37d42ef	2026-09-25 18:24:57.00901+07	91aa654e-aa09-4a4b-aaea-97d1846ee476	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	cUKFQ6+m69xP8y4oqpf1KhBi+OboQiKuZhynaiviRug=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
2850cfa9-3c8d-4a24-b745-07a7b3ae2b2b	2026-09-25 18:28:54.084846+07	3b08bc8c-5706-4b30-8f43-04881dece017	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	ZoVX3Lf51ryYl26nK5Y6r85A9V2mgFfjc+eJiWSCuT0=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
9fd5fed3-6292-4b1b-ac1d-c6108812b643	2026-09-25 18:24:57.127291+07	72284c07-375f-46f2-a608-0cd491f1a535	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	FQ86Zx40GxSU0wYyNfXuf+N+SMly79W7R1OM8FjWKuQ=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
8b4b4444-8d87-46bd-8f20-a2c98db419fd	2026-09-26 20:30:13.136691+07	89d27bcc-ff07-4d0c-b506-54cf2e1e9373	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	iux5bDX47eQVC059mJBe3oBFReuqcjr/vBRkIFfWVNM=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
570cd69f-02b8-4579-a7ec-afd35dae3093	2026-09-25 18:24:57.350468+07	b351491a-b4a7-4095-acf1-f76b382eb89c	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	lpFPCt2njuyGqOQJVc474tTSgAmqpv/3zFmRwp7SmdY=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
a41848ff-06f7-4244-91df-4611f752fa9e	2026-09-25 18:28:54.361994+07	70212c99-9a0f-4d67-bbfc-6274d7df46f3	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	9XZV+gRw292ohfyuQpNBaQwt7YqFtOWe+88niO6dJqc=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
ac2e211b-504c-4172-89a9-3daabb216669	2026-09-25 18:29:09.141785+07	96e50df0-daf6-49f9-8a17-21ac0c955c86	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	nFKgP0bL85XLYJoldDz5cq0mxOxp7oyGdvRXNrXegzk=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
1ff6d997-d963-4b7d-b52d-e001083fb14c	2026-09-26 11:12:08.245561+07	6e173d7d-4840-46b8-8b39-2c629205e3f1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	SwXeaxLFqjmhzwmA7/TNScGyndVGqMmwgxKo+UUlUQs=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
9faf61df-5900-45c3-97b2-898790b578ac	2026-09-26 09:21:04.178874+07	9da6158e-de44-4ff6-b6d5-fb02e129cd9e	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	Un88X1RQfKTC6CexSIEXMWb0iH0dnMFIdHcCNnJ48JQ=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
f79e2c74-be4e-491f-a3e0-be231051d2e0	2026-09-26 20:09:35.372822+07	84d9185e-0f0d-48b7-99db-3d6660198890	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Chrome", "country": "LocalHost", "deviceOS": "Windows NT ??", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"}	f	F0PiqcXek3nZ0IbMdnI9yQDYhXso2HWFVHfb1NmCZAk=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
eb2e65ab-eb0e-49d9-a88d-538a9548f2b9	2026-09-25 18:24:57.243389+07	f6f55e2c-078d-4325-b4b4-bed493d6e6ae	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	oh90nWWi8vTO08Kn6/jaxmQvzf60SCiEErOd/L62fCw=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
58344b8b-c77a-4e4d-b466-4bf1383dfa48	2026-09-26 09:21:07.224074+07	6ad09040-6420-4122-bcba-bf2218d76565	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	dWbqodNxS1lP6CXzPVEC6Q0pfGl7wH2D+B0nnjNoNHI=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
a01089a9-9a6b-42e1-9042-3ab02c57195b	2026-09-26 09:21:22.611559+07	9d077902-7adf-478c-b025-d1062a13609f	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	NSCmdr1LOM4X3iH+sBYlev1Nre06DvWFPMv103iwDLI=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
9848859d-1436-4da3-a403-f35e567b4362	2026-09-26 20:14:04.432144+07	f0ee6218-1f19-461f-b6b6-f38d015354af	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	Q95KcpoCWjA4txgi2Wt9IH01kjsGJhi4NmKZ2Vsmm98=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
45aa6649-3d0d-4f8e-8fcb-c65e909aad65	2026-09-30 10:44:34.484636+07	60385fa2-b3b1-4c21-b227-531cfee4405a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0"}	t	TOiixc4Q4kTDWivuiy8J8MuMxYfgDZFsD58Vb90NZQ8=	1eb771f5-9d51-40fb-85ef-81b0ba2c2bcd	\N
5a145c88-013d-479b-a2b7-2ea9311c6e24	2026-09-25 18:28:53.986899+07	dbad27ec-e5ac-4825-9d33-573a7103266d	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	uvH5lazr8hBVPJWd3Y6oXFMFhiojkNDwXgnn+CDl9/I=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
2c894494-2b24-4bf6-8445-83fdecfbe707	2026-09-26 18:39:57.111828+07	490117e9-614a-4cf3-b14d-3ddcbf0479a1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	6M4UJEXmIyW58v1IoVeMAJpWzr0joPnH3kj4/EKs5cE=	cf26d867-49f1-4c12-b35b-c79bfb2884fc	\N
542b3208-2008-41bb-92f1-9a112748cd3b	2026-09-26 09:22:44.138332+07	e458b1b5-4814-486b-8f58-664c7be07be1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	xQMYWCZUKjlWke5rRMP3d3KWz1lmTflCdkklcB9XZyk=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
b5454eca-eda1-4d03-b63f-7b62f074ec71	2026-09-26 09:23:32.701334+07	d5efc7de-c4ab-421f-bdde-375489b9d292	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	TFmiXfT8+Dp+oN9notQ5zuKZQfyWbO79Q1RnjbtqmyQ=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
e492964f-91ff-48c8-9988-19d0e71661fe	2026-09-26 09:24:08.568306+07	4e5ddcfd-8e2b-40ef-ab5e-37455fdffb33	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	IXg4DmAhnwQqrOqdJGPCREurhT5rHaO0Jwd5rzyQWjM=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
c5f9941f-97cb-4dbc-bff8-4a068c479994	2026-09-26 09:24:49.022378+07	06f7178b-d40a-495a-b08f-e454de40dd1c	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	pdzSjIwAJNHRKiyR7ShWCydFM1Hl8speXng9s1aW+HY=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
15a81f36-6450-4087-acf9-8ddb1ffb58af	2026-09-26 09:25:07.06325+07	ad123faa-ae01-41a5-bae5-78da6efa2df3	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	zp08/X/+efYmHsVLXIl1HkixL/t+R8uSsrbkb65Yrfs=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
e796ae42-51b3-4065-9e9e-d357405ab896	2026-09-26 20:13:13.795409+07	f0ee6218-1f19-461f-b6b6-f38d015354af	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	3ejCTs5+YWBPHDgEsqjzlYzE/s1Q2oV0MokYYfTeiAk=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
c4aa22ba-06b4-4d62-b875-220fead33fc0	2026-09-26 09:27:01.824486+07	94b6d469-a154-4de7-8801-6cf40b767612	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	0OtalKYX0qmiSnjSVcGTBO0El0X4TN/7fcZ2VEAcu+U=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
ae970746-d3dd-492c-8819-5a96fc246cc1	2026-09-26 09:30:32.259996+07	fb748136-cbda-42b6-afa2-83271547ba19	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	k/SDtY8AXjGTT3oLJnaiHqxf5D3e01hSd32gPLLen7s=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
efc0fead-a0f5-4827-b4c7-14ba39341f24	2026-09-26 09:32:39.048922+07	92e5df88-e7a5-4b4b-981a-c01f0ab70983	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	r8jJorbss1kQxtCwm45uCwR1P0nk8F1sCdSoiVAs0cs=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
7d32fb51-c296-469a-897e-1e0daed84dec	2026-09-26 10:05:32.568304+07	fa79be1a-51bc-4c88-b4c9-5483bfb201ac	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	9yXNLbqa04V1ZFakQEYc+CVN3Teta9CKzXq++y0HZZE=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
8eae460e-bf4b-4d11-844c-2087f9158cc1	2026-09-26 10:06:26.114683+07	e6317671-6c94-4dd2-91a3-4c3bc259637e	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	7+n3K8QDoFfWO0H8Mq6rm2DhkQmxADyEjvOKgphJgIU=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
fcba1dc7-5020-4b8d-aa8b-156d3a41fdfd	2026-09-26 10:07:06.531357+07	0a9e61c6-32a3-4759-a214-4ddb895e64d0	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	ULbUo/eeSn/ZGztzhhVkaMMqY4qoQHy18DwcakDMnUI=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
b6a6d1c2-7bc6-4560-9ba5-d493ffa91e75	2026-09-26 10:22:17.571346+07	8e35e7a6-5d73-4206-901e-61cb807a135f	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	PdK9o1/uMuTaYrZSj46+lyeEZM70v1Feb3m/rgijko0=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
57392a28-7f4f-41af-9f2a-b701e3739e42	2026-09-26 09:19:11.369652+07	51f8d35c-483c-45ca-a9b6-312a2c0fab9f	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	F0oBByTUF5Ag7ripQ7WxTVM9PYGTlrr2nmt1IL2Hxto=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
0cdf2c05-080e-44fc-a774-07019e167866	2026-09-25 18:28:54.176755+07	97322529-ead3-4563-a812-9e4f6eb57e29	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	Fxjrp0HE3XzjE48S2MmjX4N3ILvKsL0dVItBQFXJ6d0=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
aa42e0d2-9c22-406f-be58-ecf26f59374d	2026-09-26 09:17:46.553096+07	3862275d-6c11-4816-829f-7c19ff28d86c	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	hj2twHjMn7vcXMaHlYcsACPpXSp6unu/XwW3aT0w8VM=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
af0a1364-03c5-4a93-8c95-65d7523171cf	2026-09-30 11:04:19.47953+07	60385fa2-b3b1-4c21-b227-531cfee4405a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0"}	f	LZ0REd13R2HiqFowuY/mEW0HYLGiPMXuhXKeEQy19qE=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
8f2f970d-2279-424f-a701-a5504ad6f80c	2026-09-25 18:40:29.92329+07	27966123-5cfc-4c88-b497-e2c1a66bb11e	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	j2Wq30LZ/ZwomMG8I1sd9gqzxpcGF2xxjzn7AOyyZnk=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
e709af5e-543e-4c25-800b-776dc8490653	2026-09-26 09:19:50.46391+07	22abd72f-2bbf-45ed-81c5-b50318b2ca0b	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	Xadj50WxwRQkJ85Jv7h2MDa6plS+V4n2sMdvNkA9Hko=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
084cef61-50bc-4ade-aed8-e943faf3ffa9	2026-09-30 11:24:26.950262+07	cd151c41-3340-46aa-a7fb-d4546711503b	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Chrome", "country": "LocalHost", "deviceOS": "Windows NT ??", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36"}	f	6nVyyC8FFeIFYY3ImjbkSbqJPrT+lm2Nex7dRNUlqqU=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
566fe652-0c9e-4ee4-8110-893aafd0041e	2026-09-26 09:34:15.868474+07	0ff74743-9907-4bb1-b77d-847ed09dc216	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	eKojiSIdG4wSYa9ucBHgwC6CjJ8w5LCXH3xHk7QqkT0=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
54c4e3bf-af30-4f22-a337-b982a7f1c658	2026-09-26 10:03:34.799382+07	f7c6a4a4-2a58-46d5-a0df-a2c3884192c4	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	Fpub5/SDa9psNNUOPpwJFn1SROiKvmATw25fcnt9KlI=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
349bf5e9-2355-47f7-a6f9-8d0a2f85aefa	2026-09-26 10:35:33.307424+07	0f2517a7-a46b-4e91-a07b-36be969e29bb	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	d0MAfsTVmJ5zKgVpeCnTb8IkR/Kbjzt6IYfc8vpTLAc=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
22779829-39fb-4083-b10a-ff626d694143	2026-09-24 09:58:11.35755+07	f7bdd9b6-8a11-4b76-ba9f-6d1b9cfc054f	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	TTX+6oMnZeoAkkjmQYb2I/djApz+NmTT0xs9Jrzyw/A=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
b7c11d13-7eee-4f56-99b0-029b1a9089e0	2026-09-24 10:14:46.233588+07	f2cb6334-2311-444b-b74e-b984bd32ca44	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	RN42i2iwigiZyyLVnV0C/t0XpKhxdSbBfMESjWAhMz0=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
2f559a0a-8336-4b04-8714-6f218c2bd69b	2026-09-24 10:14:50.366397+07	69c1c64c-1ced-4a66-adde-f0aef44df70a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	D3v47VRSrvHtGbqowRzPsih0wRsepk6wQBgq872esaE=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
e4ef1e70-f891-4e30-964e-922011b90f78	2026-09-24 10:14:57.278602+07	2fa3f6a4-8f85-45e8-a930-9877fee0656a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	6LK66n2S+/Q7Eba42jEWmxbl4EMjU9ps8EJpU4Piufg=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
57857511-a3a4-49ce-9825-f274bf51e31d	2026-09-24 10:15:15.108179+07	9ea1c44f-3405-493a-9ba3-7dad700ab654	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	EShA7WfyhG1GSlkmL+pWRSJyjBNceQrkLWhwPWWaqEU=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
5ecafcd8-4ac7-44ae-b860-a78c0693bee1	2026-09-24 10:18:43.337468+07	d07d73b5-ae39-496d-922d-7ea889f75769	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	tCNHe304LDA+SD4bh1128YwkY4EjwOzXJ+fRkVGfJNg=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
5b3d28ba-d18e-42ab-b803-9c246de4292f	2026-09-24 10:18:49.841172+07	ff33f310-43d3-4639-992c-8f81e65780b5	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	sC631+UWYvUlQyZAdAdemRam1DqPQYZWNtfqIKm0qxk=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
1de3945d-7bf8-4fbe-833d-0207fadaf9bc	2026-09-24 10:14:33.231389+07	05aea5c7-6cf5-4b9b-a162-acb47aec9b4f	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	KPym7qEyR61HVFRcWcHqDbrLbpdQ7cT+XvWoG6hqSAs=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
e2a3de4e-f651-4fca-95d8-aaaa9059ffb8	2026-09-24 10:32:08.221822+07	a24256ba-baf5-4acd-9f08-aa4ab0cd7a71	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Python-Requests", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "python-requests/2.34.2"}	t	mg65T5BvmR3+1aGp4SrWEMEO32RNr0foq+O6g62ZxQA=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
9795bd89-fce0-4925-bf1a-52a4ff61acfa	2026-09-24 15:02:49.897512+07	a6417561-4403-40bc-92db-4292b50600ec	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Postman Runtime", "country": "LocalHost", "deviceOS": "Cloud ??", "deviceType": "Robot", "userAgentRaw": "PostmanRuntime/2.7.0"}	t	tZy0hVifv1dQLWGmSPDk+6ekQH0UsjP1vnglUdgdHV0=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
fcc3854f-49c5-4d3e-b665-7f0e14d30419	2026-09-25 16:45:47.019133+07	964c5a8b-d8dc-4f44-9c78-edaa17ff0aee	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	XGHFi9GOykm1o4PgWtGtFFYmtVsSFtDWwbFbseBlYe4=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
ec54a21a-57a6-4d02-9861-e9edf4fda74b	2026-09-25 16:47:08.876043+07	adcf06b1-710c-4ad5-858f-bc19119efd5f	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	NSg1TdXeGw1yF53v0/A4dre7TkDOJ7ClwW6omDuG/v8=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
e5e38d94-cd0d-4d3d-82b4-34e5c04cf347	2026-09-25 16:50:44.897915+07	c740bd53-6e55-480d-a7c3-c7da2e1636ed	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	q+6Kx8pO61kxuhz8HfvbCg+rSfPhhiWfQEifrkiRxAY=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
a755b2ca-df48-4b40-ae16-c5ecadef7717	2026-09-25 16:54:12.264963+07	aac6ba7e-01fb-43d2-b1b1-e544e0b2f47f	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	t	yz6APPf7lIOBLMe4YmbcVmhhzh+aas04lcrVo6Bxkh8=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
d8a3a20e-737e-4848-a726-6350bcf257b3	2026-09-25 17:01:55.641553+07	9aa598af-d674-4bc3-bc8f-380ecfab344e	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	LeMPpXhyT9Sq2elbPhEshKgGxT8K61yvqqIpiYO3QsA=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
60702c95-d3d4-48f7-ac33-5eb01b6ebec9	2026-09-25 17:54:39.287895+07	502e0003-f86e-4178-b823-f21338067e53	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	JwgXypKjDMnhdAUfqMjb1ZY3iFO2OMaQmWj5XTSPaoo=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
3931a870-e014-4906-b511-2d71d88fcca6	2026-09-25 17:55:39.260873+07	8631b6cd-d401-4f78-ac75-19f1cb13e9d4	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	DBJiP48FESJ14mLAv2MgF9yGm2t51d/TVxKQPeV5h4s=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
ef39535f-923b-4d63-8fbe-4b864e44261b	2026-09-25 17:55:58.173078+07	8654b4e0-c5e1-4e57-8d73-505b36d723ba	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	2pym2f36fs6EXbLL3z2l2RWUKp9wAD4A+ykvrnDQvBs=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
ca7099f0-2f27-4e94-bc05-6cc0d68a1fa3	2026-09-25 17:57:43.091086+07	1f14abf5-bc57-4af1-9623-21be6c03a459	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	tJrzvYRG87e9zGP1b+8oG5gz7t/s2K81FYtCavstejs=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
ad4b8bd8-2373-487e-bb12-6d85fda070f4	2026-09-25 17:58:00.953104+07	ee57774e-857f-4706-90d5-059c6b970727	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	RDZTUdqir2Lwvc3ow6lCgTbem8Fr7PkU6maTpUkRDUI=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
e462a051-c398-4221-9fa3-8a2a2254bdeb	2026-09-25 18:21:06.303396+07	0419e156-f42a-4951-bc0f-c047f766ecbf	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	28pFRuZ9OxAybtegQMuSita+qOqfqHRrdYAmEp7foxk=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
e64edc70-8e9b-493d-bb2b-dc6834dc0df5	2026-09-25 18:22:07.564032+07	d3ffe532-0c8e-4a62-a207-15c1d996c143	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	upU4qwzxRXxGWsC0UIAqybaaSN84MFtwam/vRgQsNHs=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
8b3fbada-83aa-4fdd-beb1-ff2890d0e016	2026-09-25 18:23:15.273013+07	c7e9af97-a77c-4c61-a4e9-8f9d0e4ec8fd	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	y7UIFbn+ullt3SIzbFhzpZ2QOqFaays61HK6pLE1PkI=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
764c879a-883a-4af9-86b3-4785bade1bca	2026-09-25 18:24:56.90674+07	1e275ad2-b98a-456b-924e-526258ecdd7d	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Hacker", "country": "LocalHost", "deviceOS": "Hacker", "deviceType": "Hacker", "userAgentRaw": "node"}	t	9oqhtdophPLJpKCq6VaH9XPzzmM2ltmT+HZ3IYRew5w=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
7f6486e8-7c20-4ae0-94e3-14a3f8dd4cb5	2026-09-29 15:51:01.660519+07	60385fa2-b3b1-4c21-b227-531cfee4405a	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0"}	t	2oUUzPinPwOyvuMC4juPx9B8m/6pyolUjmjwyMdoSzE=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
3059c2c6-8067-4426-81ef-571b45bcd142	2026-09-30 11:32:59.601531+07	71d09b9c-65ba-472f-811d-bcfeac102e75	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "WindowsPowerShell", "country": "LocalHost", "deviceOS": "Windows 10.0", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9444"}	f	QKqmm5vV96u0/xxBTC4ePJ9ggEdKPNLJS7Bu3bpjU+o=	fca9aa46-b141-415f-ab4c-9f336bdfd46e	\N
42bf8966-9c5b-44ab-aa91-f55d80a1e25f	2026-09-26 16:49:27.436153+07	490117e9-614a-4cf3-b14d-3ddcbf0479a1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	AhiT8o19xlb56cHLnG+hLmqddW62C+xT2/nSa4DJVBQ=	a3214f8e-94d1-4f9e-80c7-bd66dd570a78	\N
7a35a04b-fd04-4bf0-bcb6-ddd29dafeb4a	2026-09-26 18:59:46.158254+07	490117e9-614a-4cf3-b14d-3ddcbf0479a1	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	R88E63YgFJ9zqd9pRQxWe+CfafSujYzttapEKQcYyGM=	1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	\N
c2542e28-96f9-4b09-936b-f5f5c827b0b0	2026-09-26 10:21:28.154376+07	3807a79c-5086-4b45-a396-894c42515711	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	GEm5vUk8y5pstqHtiOhrDsJD1FhhzeeqKfKtmgk/NHo=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
ada1ca53-cf26-4d1d-8e2c-3c1567bc5f10	2026-09-26 10:22:51.435337+07	8896ee42-3931-4fbe-9d6f-13da19fa6861	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Edge", "country": "LocalHost", "deviceOS": "Windows >=10", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0"}	t	l75Hqf06IgmmXZlHbkHopvRHUeseL40XdKXWv16EGfA=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
2b913b20-8dad-432b-a7a6-c8128f816880	2026-09-26 11:57:41.437531+07	c1c81a2f-8f2a-41ec-b0e8-c8075815fc63	{"isp": "Local Network", "city": "LocalHost", "ipAddr": "LocalHost", "browser": "Chrome", "country": "LocalHost", "deviceOS": "Windows NT ??", "deviceType": "Desktop", "userAgentRaw": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"}	t	BHqyGr6u8V7mFEBev83CDq8XPSdhy746bc5aDe/bDu8=	a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	\N
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
1108cc0f-8b18-4ada-962c-f9e1f3ebe4ff	12	2004-08-14	nguyenminhduc@company.com	Hoàng	Nam	2026-08-20	Lê Minh Trung	$2a$10$ZJbAWr7h0DaEJpW0GSfIReY9bBCRimMvEOAWeFSms9.gIEwwK6.Z6	/uploads/avatars/93eeb475-5acc-433b-8032-dd6d302d112d.webp	0	0190abcd-7890-7def-89ab-cdef0123456d	584a3e62-c23b-4925-93a6-208ca87e068e	[-0.10619169,0.084548436,0.066045314,0.016829323,-0.093992755,-0.018793397,-0.043872394,-0.21016113,0.12352578,-0.10384144,0.2556409,-0.06241406,-0.18526869,-0.15330496,-0.0353977,0.20238957,-0.12705497,-0.14674178,-0.069980845,-0.022015743,0.026622372,-0.042635836,0.05603297,0.06920933,-0.09702276,-0.35008663,-0.10961397,-0.086113915,-0.016839635,-0.07287155,-0.08335102,0.09441249,-0.2262931,-0.020945301,-0.039964415,0.10099664,-0.037690915,-0.07338695,0.17311388,-0.0389892,-0.19109572,-0.041405257,0.03253486,0.17420317,0.19381803,0.0309595,0.048412714,-0.06838818,0.031029504,-0.13978843,0.05773215,0.1277563,0.047688328,0.06003608,-0.08328276,-0.17518637,-0.014741531,0.054116495,-0.10312985,0.0071776193,0.086150914,-0.16667384,-0.13547012,-0.03182113,0.27165338,0.17281945,-0.09066216,-0.17251578,0.15517609,-0.16886522,-0.0625281,-0.01618588,-0.19096264,-0.18379802,-0.34069726,0.06564736,0.36068198,0.09090418,-0.1849247,0.04976602,-0.037148826,0.0655646,0.09101144,0.17222047,-0.04485344,0.071615405,-0.10339195,0.039500203,0.17382105,-0.054993603,-0.048204977,0.25207138,-0.038520876,0.06165527,0.039843474,-0.019166596,0.057451136,0.036210798,-0.10263221,0.045646716,0.09630408,-0.023274984,0.009234368,0.073523924,-0.10243351,0.0677551,-0.012133532,0.07409682,0.04812538,-0.044437435,-0.16801693,-0.11789357,0.15626271,-0.19849461,0.20211469,0.17161456,0.06350903,0.14791948,0.17422035,0.18383321,0.030738238,-0.013313028,-0.20282179,0.038746484,0.16240126,-0.0249238,0.07262002,0.06656713]	EMP001	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d	12	1995-01-15	sysadmin@company.com	Nguyễn	Male	2024-01-01	Văn Admin	$2a$10$ZJbAWr7h0DaEJpW0GSfIReY9bBCRimMvEOAWeFSms9.gIEwwK6.Z6	https://ui-avatars.com/api/?name=System+Admin&background=0D8ABC&color=fff	0	0190abcd-1234-7def-89ab-cdef01234567	0190abcd-7006-7def-89ab-cdef01234573	\N	EMP027	52a5e36a-8fc5-4142-8d20-0a2436ab59a3	t
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
c0a80107-a0db-177e-81a0-dbcf7e050009	1	17:30:00	t	13:30:00	12:00:00	08:00:00	c0a80107-a0db-177e-81a0-dbcf7e040008
c0a80107-a0db-177e-81a0-dbcf7e05000a	2	17:30:00	t	13:30:00	12:00:00	08:00:00	c0a80107-a0db-177e-81a0-dbcf7e040008
c0a80107-a0db-177e-81a0-dbcf7e05000b	3	17:30:00	t	13:30:00	12:00:00	08:00:00	c0a80107-a0db-177e-81a0-dbcf7e040008
c0a80107-a0db-177e-81a0-dbcf7e05000c	4	17:30:00	t	13:30:00	12:00:00	08:00:00	c0a80107-a0db-177e-81a0-dbcf7e040008
c0a80107-a0db-177e-81a0-dbcf7e05000d	5	17:30:00	t	13:30:00	12:00:00	08:00:00	c0a80107-a0db-177e-81a0-dbcf7e040008
c0a80107-a0db-177e-81a0-dbcf7e05000e	6	12:00:00	t	\N	\N	08:00:00	c0a80107-a0db-177e-81a0-dbcf7e040008
c0a80107-a0db-177e-81a0-dbcf7e05000f	7	00:00:00	f	\N	\N	00:00:00	c0a80107-a0db-177e-81a0-dbcf7e040008
\.


--
-- Data for Name: work_shifts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_shifts (shift_id, name) FROM stdin;
c0a80107-a0db-177e-81a0-dbcf7e040008	Ca Kỹ Thuật & Vận Hành (T2-T7)
52a5e36a-8fc5-4142-8d20-0a2436ab59a3	Giờ hành chính (T2-T6)
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
    ADD CONSTRAINT pending_users_pkey PRIMARY KEY (pending_id);


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
-- Name: user_permission_grants user_permission_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permission_grants
    ADD CONSTRAINT user_permission_grants_pkey PRIMARY KEY (permission, user_id);


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
-- Name: user_contracts fkaax71dyljd3ogi797b9ufe1pr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contracts
    ADD CONSTRAINT fkaax71dyljd3ogi797b9ufe1pr FOREIGN KEY (user_id) REFERENCES public.users(user_id);


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
-- Name: pending_users pending_users_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT pending_users_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- Name: pending_users pending_users_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT pending_users_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: pending_users pending_users_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT pending_users_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(job_id);


--
-- Name: pending_users pending_users_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_users
    ADD CONSTRAINT pending_users_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.work_shifts(shift_id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict iMPEBINDtocfzMur5h6ynnaLdQHrl7QXA0tt7q2bRjK0zPQyTAIbrpc67ZfgJxM

