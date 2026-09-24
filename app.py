import streamlit as st
import mysql.connector
import pandas as pd
import plotly.express as px
import os

# ============================================================
# PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="Hotel Reservation Analytics",
    page_icon="🏨",
    layout="wide"
)

# ============================================================
# DATABASE CONNECTION
# ============================================================

@st.cache_resource
def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password= "root",
        database="hotel_reservation_analytics"
    )


# ============================================================
# RUN SQL QUERY
# ============================================================

@st.cache_data
def run_query(query):
    conn = get_connection()
    return pd.read_sql(query, conn)


# ============================================================
# SIDEBAR
# ============================================================

st.sidebar.title("🏨 Hotel Analytics")

page = st.sidebar.radio(
    "Select Dashboard",
    [
        "Overview",
        "Booking Analysis",
        "Guest Analysis",
        "Stay Analysis",
        "Hotel & Room Analysis",
        "Staff Analysis"
    ]
)


# ============================================================
# OVERVIEW
# ============================================================

if page == "Overview":

    st.title("🏨 Hotel Reservation Analytics Dashboard")
    st.markdown("### Overall Performance Overview")

    # ---------------- KPI DATA ----------------

    guests = run_query("""
        SELECT COUNT(*) AS total_guests
        FROM guests
    """)

    bookings = run_query("""
        SELECT COUNT(*) AS total_bookings
        FROM bookings
    """)

    stays = run_query("""
        SELECT COUNT(*) AS total_stays
        FROM stays
    """)

    revenue = run_query("""
        SELECT SUM(total_amount) AS total_revenue
        FROM bookings
    """)

    avg_booking = run_query("""
        SELECT ROUND(AVG(total_amount),2) AS avg_booking
        FROM bookings
    """)

    conversion = run_query("""
        SELECT ROUND(
            COUNT(DISTINCT s.booking_id) * 100.0 /
            COUNT(DISTINCT b.booking_id), 2
        ) AS conversion_rate
        FROM bookings b
        LEFT JOIN stays s
        ON b.booking_id = s.booking_id
    """)

    # ---------------- KPI CARDS ----------------

    col1, col2, col3 = st.columns(3)

    col1.metric(
        "👥 Total Guests",
        f"{guests.iloc[0,0]:,}"
    )

    col2.metric(
        "📑 Total Bookings",
        f"{bookings.iloc[0,0]:,}"
    )

    col3.metric(
        "🏨 Total Stays",
        f"{stays.iloc[0,0]:,}"
    )

    col4, col5, col6 = st.columns(3)

    col4.metric(
        "💰 Total Revenue",
        f"₹{revenue.iloc[0,0]:,.2f}"
    )

    col5.metric(
        "💵 Avg Booking Value",
        f"₹{avg_booking.iloc[0,0]:,.2f}"
    )

    col6.metric(
        "📈 Booking Coverage",
        f"{conversion.iloc[0,0]}%"
    )

    st.divider()

    # ========================================================
    # MONTHLY BOOKING TREND
    # ========================================================

    monthly = run_query("""
        SELECT
            YEAR(booking_date) AS booking_year,
            MONTH(booking_date) AS booking_month,
            COUNT(*) AS total_bookings,
            SUM(total_amount) AS revenue
        FROM bookings
        GROUP BY
            YEAR(booking_date),
            MONTH(booking_date)
        ORDER BY booking_year, booking_month
    """)

    monthly["period"] = (
        monthly["booking_year"].astype(str)
        + "-"
        + monthly["booking_month"].astype(str).str.zfill(2)
    )

    fig = px.line(
        monthly,
        x="period",
        y="total_bookings",
        markers=True,
        title="Monthly Booking Trend"
    )

    st.plotly_chart(fig, use_container_width=True)

    # ========================================================
    # BOOKING CHANNEL
    # ========================================================

    channel = run_query("""
        SELECT
            booking_channel,
            COUNT(*) AS total_bookings,
            SUM(total_amount) AS revenue
        FROM bookings
        GROUP BY booking_channel
        ORDER BY revenue DESC
    """)

    col1, col2 = st.columns(2)

    with col1:

        fig = px.bar(
            channel,
            x="booking_channel",
            y="total_bookings",
            title="Bookings by Channel"
        )

        st.plotly_chart(fig, use_container_width=True)

    with col2:

        fig = px.pie(
            channel,
            names="booking_channel",
            values="revenue",
            title="Revenue by Booking Channel"
        )

        st.plotly_chart(fig, use_container_width=True)


# ============================================================
# BOOKING ANALYSIS
# ============================================================

elif page == "Booking Analysis":

    st.title("📑 Booking Analysis")

    # --------------------------------------------------------
    # FILTER
    # --------------------------------------------------------

    hotels = run_query("""
        SELECT hotel_name
        FROM hotels
        ORDER BY hotel_name
    """)

    selected_hotel = st.selectbox(
        "Select Hotel",
        ["All Hotels"] + hotels["hotel_name"].tolist()
    )

    # --------------------------------------------------------
    # BOOKINGS BY HOTEL
    # --------------------------------------------------------

    hotel_query = """
        SELECT
            h.hotel_name,
            COUNT(b.booking_id) AS total_bookings
        FROM hotels h
        JOIN bookings b
        ON h.hotel_id = b.hotel_id
    """

    if selected_hotel != "All Hotels":
        hotel_query += f"""
            WHERE h.hotel_name = '{selected_hotel}'
        """

    hotel_query += """
        GROUP BY h.hotel_id, h.hotel_name
        ORDER BY total_bookings DESC
    """

    hotel_bookings = run_query(hotel_query)

    fig = px.bar(
        hotel_bookings,
        x="hotel_name",
        y="total_bookings",
        title="Bookings by Hotel"
    )

    st.plotly_chart(fig, use_container_width=True)

    # --------------------------------------------------------
    # BOOKING CHANNEL
    # --------------------------------------------------------

    channel = run_query("""
        SELECT
            booking_channel,
            COUNT(*) AS total_bookings,
            SUM(total_amount) AS revenue,
            ROUND(AVG(total_amount),2) AS avg_booking_value
        FROM bookings
        GROUP BY booking_channel
        ORDER BY total_bookings DESC
    """)

    st.subheader("Booking Channel Performance")

    st.dataframe(
        channel,
        use_container_width=True,
        hide_index=True
    )

    col1, col2 = st.columns(2)

    with col1:

        fig = px.bar(
            channel,
            x="booking_channel",
            y="total_bookings",
            title="Bookings by Channel"
        )

        st.plotly_chart(fig, use_container_width=True)

    with col2:

        fig = px.bar(
            channel,
            x="booking_channel",
            y="revenue",
            title="Revenue by Channel"
        )

        st.plotly_chart(fig, use_container_width=True)

    # --------------------------------------------------------
    # ROOM TYPE
    # --------------------------------------------------------

    room_type = run_query("""
        SELECT
            room_type_requested,
            COUNT(*) AS total_bookings,
            SUM(total_amount) AS revenue,
            ROUND(AVG(nights_booked),2) AS avg_nights
        FROM bookings
        GROUP BY room_type_requested
        ORDER BY total_bookings DESC
    """)

    st.subheader("Room Type Demand")

    fig = px.bar(
        room_type,
        x="room_type_requested",
        y="total_bookings",
        title="Most Requested Room Types"
    )

    st.plotly_chart(fig, use_container_width=True)


# ============================================================
# GUEST ANALYSIS
# ============================================================

elif page == "Guest Analysis":

    st.title("👥 Guest Analysis")

    # --------------------------------------------------------
    # GUEST TYPE
    # --------------------------------------------------------

    guest_type = run_query("""
        SELECT
            g.guest_type,
            COUNT(DISTINCT g.guest_id) AS total_guests,
            COUNT(b.booking_id) AS total_bookings,
            SUM(b.total_amount) AS revenue,
            ROUND(AVG(b.total_amount),2) AS avg_booking_amount
        FROM guests g
        JOIN bookings b
        ON g.guest_id = b.guest_id
        GROUP BY g.guest_type
    """)

    st.subheader("Individual vs Corporate Guests")

    st.dataframe(
        guest_type,
        use_container_width=True,
        hide_index=True
    )

    fig = px.bar(
        guest_type,
        x="guest_type",
        y="revenue",
        title="Revenue by Guest Type"
    )

    st.plotly_chart(fig, use_container_width=True)

    # --------------------------------------------------------
    # TOP GUESTS
    # --------------------------------------------------------

    top_guests = run_query("""
        SELECT
            g.guest_name,
            COUNT(b.booking_id) AS bookings,
            SUM(b.total_amount) AS total_spending
        FROM guests g
        JOIN bookings b
        ON g.guest_id = b.guest_id
        GROUP BY g.guest_id, g.guest_name
        ORDER BY total_spending DESC
        LIMIT 10
    """)

    st.subheader("🏆 Top 10 Guests by Spending")

    fig = px.bar(
        top_guests,
        x="total_spending",
        y="guest_name",
        orientation="h",
        title="Top Guests by Spending"
    )

    st.plotly_chart(fig, use_container_width=True)

    # --------------------------------------------------------
    # CITY ANALYSIS
    # --------------------------------------------------------

    city = run_query("""
        SELECT
            g.city,
            COUNT(DISTINCT g.guest_id) AS guests,
            COUNT(b.booking_id) AS bookings,
            SUM(b.total_amount) AS revenue
        FROM guests g
        LEFT JOIN bookings b
        ON g.guest_id = b.guest_id
        GROUP BY g.city
        ORDER BY bookings DESC
    """)

    st.subheader("Guest Activity by City")

    st.dataframe(
        city,
        use_container_width=True,
        hide_index=True
    )


# ============================================================
# STAY ANALYSIS
# ============================================================

elif page == "Stay Analysis":

    st.title("🏨 Stay Performance Analysis")

    # --------------------------------------------------------
    # STAY STATUS
    # --------------------------------------------------------

    status = run_query("""
        SELECT
            status,
            COUNT(*) AS total_stays,
            ROUND(
                COUNT(*) * 100.0 /
                (SELECT COUNT(*) FROM stays), 2
            ) AS percentage
        FROM stays
        GROUP BY status
        ORDER BY total_stays DESC
    """)

    col1, col2 = st.columns(2)

    with col1:

        fig = px.pie(
            status,
            names="status",
            values="total_stays",
            title="Stay Outcomes"
        )

        st.plotly_chart(fig, use_container_width=True)

    with col2:

        st.dataframe(
            status,
            use_container_width=True,
            hide_index=True
        )

    # --------------------------------------------------------
    # HOTEL PROBLEM RATE
    # --------------------------------------------------------

    problem_rate = run_query("""
        SELECT
            h.hotel_name,
            COUNT(s.stay_id) AS total_stays,
            SUM(
                CASE
                    WHEN s.status IN ('Cancelled','No-show')
                    THEN 1
                    ELSE 0
                END
            ) AS problem_stays,
            ROUND(
                SUM(
                    CASE
                        WHEN s.status IN ('Cancelled','No-show')
                        THEN 1
                        ELSE 0
                    END
                ) * 100.0 /
                COUNT(s.stay_id), 2
            ) AS problem_rate
        FROM hotels h
        JOIN bookings b
        ON h.hotel_id = b.hotel_id
        JOIN stays s
        ON b.booking_id = s.booking_id
        GROUP BY h.hotel_id, h.hotel_name
        ORDER BY problem_rate DESC
    """)

    st.subheader("⚠ Hotel Cancellation / No-show Rate")

    fig = px.bar(
        problem_rate,
        x="hotel_name",
        y="problem_rate",
        title="Problem Rate by Hotel"
    )

    st.plotly_chart(fig, use_container_width=True)

    # --------------------------------------------------------
    # SERVICE REQUESTS
    # --------------------------------------------------------

    service = run_query("""
        SELECT
            status,
            COUNT(*) AS stays,
            ROUND(AVG(service_requests),2)
            AS avg_service_requests
        FROM stays
        GROUP BY status
    """)

    st.subheader("Service Requests by Stay Status")

    fig = px.bar(
        service,
        x="status",
        y="avg_service_requests",
        title="Average Service Requests"
    )

    st.plotly_chart(fig, use_container_width=True)


# ============================================================
# HOTEL & ROOM ANALYSIS
# ============================================================

elif page == "Hotel & Room Analysis":

    st.title("🏨 Hotel & Room Analysis")

    # --------------------------------------------------------
    # HOTEL REVENUE
    # --------------------------------------------------------

    hotel_revenue = run_query("""
        SELECT
            h.hotel_name,
            COUNT(b.booking_id) AS bookings,
            SUM(b.total_amount) AS revenue
        FROM hotels h
        JOIN bookings b
        ON h.hotel_id = b.hotel_id
        GROUP BY h.hotel_id, h.hotel_name
        ORDER BY revenue DESC
    """)

    st.subheader("Hotel Revenue")

    fig = px.bar(
        hotel_revenue.head(10),
        x="hotel_name",
        y="revenue",
        title="Top 10 Hotels by Revenue"
    )

    st.plotly_chart(fig, use_container_width=True)

    # --------------------------------------------------------
    # REVENUE PER ROOM
    # --------------------------------------------------------

    revenue_room = run_query("""
        SELECT
            h.hotel_name,
            h.total_rooms,
            SUM(b.total_amount) AS revenue,
            ROUND(
                SUM(b.total_amount) /
                h.total_rooms, 2
            ) AS revenue_per_room
        FROM hotels h
        JOIN bookings b
        ON h.hotel_id = b.hotel_id
        GROUP BY
            h.hotel_id,
            h.hotel_name,
            h.total_rooms
        ORDER BY revenue_per_room DESC
    """)

    st.subheader("Revenue per Room")

    st.dataframe(
        revenue_room,
        use_container_width=True,
        hide_index=True
    )

    # --------------------------------------------------------
    # ROOM TYPES
    # --------------------------------------------------------

    room_types = run_query("""
        SELECT
            r.room_type,
            COUNT(s.stay_id) AS total_stays,
            ROUND(AVG(s.nights_stayed),2)
            AS avg_nights,
            ROUND(AVG(s.service_requests),2)
            AS avg_service_requests
        FROM rooms r
        JOIN stays s
        ON r.room_id = s.room_id
        GROUP BY r.room_type
        ORDER BY total_stays DESC
    """)

    st.subheader("Room Type Usage")

    fig = px.bar(
        room_types,
        x="room_type",
        y="total_stays",
        title="Most Used Room Types"
    )

    st.plotly_chart(fig, use_container_width=True)


# ============================================================
# STAFF ANALYSIS
# ============================================================

elif page == "Staff Analysis":

    st.title("👨‍💼 Staff Performance Analysis")

    # --------------------------------------------------------
    # STAFF PERFORMANCE
    # --------------------------------------------------------

    staff = run_query("""
        SELECT
            st.staff_id,
            st.staff_name,
            COUNT(s.stay_id) AS stays_handled,
            ROUND(AVG(s.nights_stayed),2)
            AS avg_nights,
            ROUND(AVG(s.stay_duration_hrs),2)
            AS avg_duration_hours,
            st.rating
        FROM staff st
        JOIN stays s
        ON st.staff_id = s.staff_id
        GROUP BY
            st.staff_id,
            st.staff_name,
            st.rating
        ORDER BY stays_handled DESC
    """)

    st.subheader("Staff Performance")

    st.dataframe(
        staff,
        use_container_width=True,
        hide_index=True
    )

    # --------------------------------------------------------
    # STAYS HANDLED
    # --------------------------------------------------------

    fig = px.bar(
        staff.head(15),
        x="staff_name",
        y="stays_handled",
        title="Top Staff by Stays Handled"
    )

    st.plotly_chart(fig, use_container_width=True)

    # --------------------------------------------------------
    # STAFF RATING
    # --------------------------------------------------------

    fig = px.scatter(
        staff,
        x="stays_handled",
        y="rating",
        size="avg_duration_hours",
        hover_name="staff_name",
        title="Staff Rating vs Stays Handled"
    )

    st.plotly_chart(fig, use_container_width=True)


# ============================================================
# FOOTER
# ============================================================

st.sidebar.divider()
st.sidebar.caption("Hotel Reservation Analytics | SQL + Python + Streamlit")