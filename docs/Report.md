# CS2102 Project Report - Team 110

| Member name | Student number | Responsibilities |
|---|---|---|
| Low Zhen Wei Jerrell | A0214232X | xx |
| Li Xi Yuan | A0XX | XX |
| Nigel Ng | A0217408H | XX |

## Table of contents
1. [ER data model](#ER-data-model)
1. [Relational database schema](#Relational-database-schema)
    1. [non-trivial design decisions](#non-trivial-design-decisions)
    1. [application constraints not captured](#application-constraints-not-captured)
    1. [triggers used to enforce constraints](#triggers-used-to-enforce-constraints)
1. [Interesting triggers implemented](#interesting-triggers-implemented)
1. [Analysis of normal forms of relational database schema](#analysis-of-normal-forms-of-relational-database-schema)
    1. tablex.
    1. tabley
    1. tablez
1. [Reflections](#reflections)
    1. [Difficulties encountered](#difficulties-encountered)
    1. [Lessons learnt from project](#lessons-learnt-from-project)
---
## ER data model
We used the [reference ER diagram](./ER.pdf) distributed as there was ambiguity in our previous ER submission.

## Relational database schema

### non-trivial design decisions

#### Using Timestamp for sessions

We considered using a single Timestamp attribute to represent `Time` in sessions, rather than the conventional `Date` and `Time` implementation suggested.
The driving factor for this is the strong dependence needed by `Sessions` with respect to other tables. For instance, the `room`, `floor`, `rname` attributes of `Meeting Rooms`. This dependence thus makes it incredibly difficult to generate "random" data for testing, thus we implemented a procedure add_random_sessions which takes the relevant data from the tables , `eid`, `booker_eid` etc. and adds them into Sessions for the database dump. In particular the `Timestamp` property allows us to generate a single attribute of data representing `Time` and `Date` using the current_timestamp default function provided by PSQL, and by implementing a check to verify that it generates timings by the hour - e.g. `15:00 vs 13:59` where the former is accepted, and the latter throws an exception.

### application constraints not captured

### triggers used to enforce constraints

## Interesting triggers implemented

### 1. Generation of company email when adding an employee

This trigger is called upon addition of an employee into the companies' database by the procedure `add_employee`. 

There are a few interesting properties of this trigger, which we'll demonstrate in sequential order by example.

For instance, take an employee with the name of [ABCDEF GHIJK Zuzu](https://mustsharenews.com/abcdef-ghijk-zuzu/),
1. extraction of initials from the name
With the name "ABCDEF GHIJK Zuzu", the Initials would be A, G and Z corresponding by the capitalisation of each word seperated by a whitespace.

2. concatenation with employee ID and company's email
For the company's email, we couldn't use `gmail.com` due to the possibility of the email already existing. Thus we considered a fictional email `gsnail.com`, which is similar.

Thus, when we enter the following command, assuming that `did = 1` exists and there are 20 employees already in the company, naturally Zuzu's eid would be 21.

 Hence,

`CALL add_employee('ABCDEF GHIJK Zuzu', '+65-6969 4200', 'Junior', 1 );` would display the following employee information:

` 21 | ABCDEF GHIJK Zuzu    | AGZ21@gsnail.com | <home office null>| +65-6969 4200     | <office contact null> | <resigned date null> |   1 | Junior`

### 2. 

### 3. 

## Analysis of normal forms of relational database schema

### table x.

## Reflections

### Difficulties encountered

### Lessons learnt from project
