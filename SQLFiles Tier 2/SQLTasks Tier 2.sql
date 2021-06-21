/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
*/

/* 
Paid Facilities for Members:
Tennis Court 1
Tennis Court 2
Massage Room 1
Massage Room 2
Squash Court
*/

select name 
from Facilities
where membercost > 0

/* Q2: How many facilities do not charge a fee to members? */

/* Free Facilities for Members = 4 */

select count(name) as free_facilities
from Facilities
where membercost = 0

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

select facid, name, membercost, monthlymaintenance
from Facilities
where membercost > 0
and membercost < 0.2*monthlymaintenance

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

select *
from Facilities
having facid in (1,5)

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

select name, 
case when monthlymaintenance > 100 then 'expensive'
	else 'cheap' end as monthly_maintenance_cost
from Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

select firstname, surname
from Members
where joindate = (select max(joindate) from Members)

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

select distinct concat(m.firstname, ' ', m.surname) as membername, f.name as tenniscourt
from Facilities as f
inner join Bookings as b
on f.facid = b.facid
inner join Members as m
on b.memid = m.memid
where f.name like 'Tennis Court%'
order by membername, tenniscourt

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

select b.bookid, 
		f.name, 
		concat(m.firstname, ' ', m.surname) as membername,
		case when b.memid > 0 then f.membercost * b.slots
		else f.guestcost * b.slots end as cost
from Bookings as b
left join Members as m
on b.memid = m.memid
left join Facilities as f
on b.facid = f.facid
where starttime like '2012-09-14%'
and case when b.memid > 0 then f.membercost * b.slots
	else f.guestcost * b.slots end > 30

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

select sub.bookid, 
		sub.name, 
		concat(m.firstname, ' ', m.surname) as membername,
		sub.cost
from (select 
      f.name, 
      b.memid, 
      b.bookid,
      case when b.memid > 0 then f.membercost * b.slots
	else f.guestcost * b.slots end as cost
      from Bookings as b
      left join Facilities as f
      on b.facid = f.facid
     where starttime like '2012-09-14%') as sub
left join Members as m
on sub.memid = m.memid
where cost > 30

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
*/
import sqlite3
from sqlite3 import Error

 
def create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by the db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        print(sqlite3.version)
    except Error as e:
        print(e)
 
    return conn

 
def select_all_tasks(conn):
    """
    Query all rows in the tasks table
    :param conn: the Connection object
    :return:
    """
    cur = conn.cursor()
    
    query1 = """
    select name, total_revenue
    from
    (select f.name, 
            sum(revenue) as total_revenue
        from Facilities as f
        inner join
            (select b.bookid, 
                    f.facid,
                    case when memid = 0 then f.guestcost*b.slots
                    else f.membercost*b.slots end as revenue
            from Bookings as b
            left join Facilities as f
            on b.facid = f.facid) as insub
        on f.facid = insub.facid
        group by name
        order by total_revenue) as outsub
    where outsub.total_revenue < 1000
        """
    cur.execute(query1)
 
    rows = cur.fetchall()
 
    for row in rows:
        print(row)


def main():
    database = "sqlite_db_pythonsqlite.db"
 
    # create a database connection
    conn = create_connection(database)
    with conn: 
        print("2. Query all tasks")
        select_all_tasks(conn)
 
 
if __name__ == '__main__':
    main()

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

import sqlite3
from sqlite3 import Error

 
def create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by the db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        print(sqlite3.version)
    except Error as e:
        print(e)
 
    return conn

 
def select_all_tasks(conn):
    """
    Query all rows in the tasks table
    :param conn: the Connection object
    :return:
    """
    cur = conn.cursor()
    
    query1 = """
      select m.memid, m.surname, m.firstname, 
        case when m.recommendedby = 0 then null
        else r.name end as recommender
    from Members as m
    left join (
        select memid, (firstname || ' ' || surname) as name 
        from Members) as r
    on m.recommendedby = r.memid
    order by m.surname, m.firstname
        """
    cur.execute(query1)
 
    rows = cur.fetchall()
 
    for row in rows:
        print(row)


def main():
    database = "sqlite_db_pythonsqlite.db"
 
    # create a database connection
    conn = create_connection(database)
    with conn: 
        print("2. Query all tasks")
        select_all_tasks(conn)
 
 
if __name__ == '__main__':
    main()

/* Q12: Find the facilities with their usage by member, but not guests */
import sqlite3
from sqlite3 import Error

 
def create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by the db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        print(sqlite3.version)
    except Error as e:
        print(e)
 
    return conn

 
def select_all_tasks(conn):
    """
    Query all rows in the tasks table
    :param conn: the Connection object
    :return:
    """
    cur = conn.cursor()
    
    query1 = """
      select f.name as facility, b.memid, m.firstname, m.surname, count(b.bookid) as n_bookings
    from Bookings as b
    left join Facilities as f
    on f.facid = b.facid
    left join Members as m
    on b.memid = m.memid
    where b.memid != 0
    group by f.name, b.memid
    order by f.name, b.memid
        """
    cur.execute(query1)
 
    rows = cur.fetchall()
 
    for row in rows:
        print(row)


def main():
    database = "sqlite_db_pythonsqlite.db"
 
    # create a database connection
    conn = create_connection(database)
    with conn: 
        print("2. Query all tasks")
        select_all_tasks(conn)
 
 
if __name__ == '__main__':
    main()

/* Alternate answer for Q12 if looking for agg table*/

import sqlite3
from sqlite3 import Error

 
def create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by the db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        print(sqlite3.version)
    except Error as e:
        print(e)
 
    return conn

 
def select_all_tasks(conn):
    """
    Query all rows in the tasks table
    :param conn: the Connection object
    :return:
    """
    cur = conn.cursor()
    
    query1 = """
     select f.name as facility, count(distinct b.memid) as n_members_used_facility, count(b.bookid) as n_bookings
    from Bookings as b
    left join Facilities as f
    on f.facid = b.facid
    where b.memid != 0
    group by f.name
    order by f.name
        """
    cur.execute(query1)
 
    rows = cur.fetchall()
 
    for row in rows:
        print(row)


def main():
    database = "sqlite_db_pythonsqlite.db"
 
    # create a database connection
    conn = create_connection(database)
    with conn: 
        print("2. Query all tasks")
        select_all_tasks(conn)
 
 
if __name__ == '__main__':
    main()
    
/* Q13: Find the facilities usage by month, but not guests */
import sqlite3
from sqlite3 import Error

 
def create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by the db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        print(sqlite3.version)
    except Error as e:
        print(e)
 
    return conn

 
def select_all_tasks(conn):
    """
    Query all rows in the tasks table
    :param conn: the Connection object
    :return:
    """
    cur = conn.cursor()
    
    query1 = """
     select f.name as facility, 
     strftime('%m',b.starttime) as month, 
     count(b.bookid) as n_bookings
    from Bookings as b
    left join Facilities as f
    on f.facid = b.facid
    where b.memid != 0
    group by f.name, month
    order by f.name, month
        """
    cur.execute(query1)
 
    rows = cur.fetchall()
 
    for row in rows:
        print(row)


def main():
    database = "sqlite_db_pythonsqlite.db"
 
    # create a database connection
    conn = create_connection(database)
    with conn: 
        print("2. Query all tasks")
        select_all_tasks(conn)
 
 
if __name__ == '__main__':
    main()
