import Navbar from "../components/Navbar";
import Sidebar from "../components/Sidebar";
import { useEffect } from "react";
import axios from "axios";
import { DASHBOARD_API_ENDPOINT } from "../services/APIs";
import Potholes from "../assets/Potholes.png";
import WaterLoggings from "../assets/WaterLoggings.png";
import Fixed from "../assets/Fixed.png";
import ResponseTime from "../assets/ResponseTime.png";
import Growth from "../assets/Growth.png";
import StatCard from "../components/StatCard";
import { setPending, setResolved, setRejected, setTotal, setInProgress} from "../services/statSlice";
import { setSunday, setMonday, setTuesday, setWednesday, setThursday, setFriday, setSaturday } from "../services/dailyDataSlice";
import { useDispatch, useSelector} from "react-redux";
import DailyTrend from "../components/DailyTrend";

function DashBoardPage() {
  const dispatch = useDispatch();
  const pending = useSelector(state => state.stat.pending);
  const rejected = useSelector(state => state.stat.rejected);
  const resolved = useSelector(state => state.stat.resolved);
  const total = useSelector(state => state.stat.total);
  const inProgress = useSelector(state => state.stat.inProgress);

  const accessToken = localStorage.getItem("accessToken");

  useEffect(() => {
    const fetchData = async () => {
      try{
        const res = await axios.get(`${DASHBOARD_API_ENDPOINT}summary/`,
          {
            headers: {
                Authorization: `Bearer ${accessToken}`,
            },
          withCredentials: true,
        });
        console.log("API Response: ", res.data); 
        dispatch(setPending(res.data.totals.pending));
        dispatch(setRejected(res.data.totals.rejected));
        dispatch(setResolved(res.data.totals.resolved));
        dispatch(setTotal(res.data.totals.total_reports));
        dispatch(setInProgress(res.data.totals.in_progress));

        const dispatchers = {
          Sunday: setSunday,
          Monday: setMonday,
          Tuesday: setTuesday,
          Wednesday: setWednesday,
          Thursday: setThursday,
          Friday: setFriday,
          Saturday: setSaturday,
        };

        res.data.trend_last_7_days.forEach((item) => {
          const dayName = new Date(item.day).toLocaleDateString('en-US', { weekday: 'long' });
          dispatch(dispatchers[dayName](item.count));
        });

      }catch(error){
        console.error("Error fetching data: ", error);
      }
    };
    fetchData();
  },[]);

  return (
    <div className="flex flex-col h-screen overflow-hidden">
      <Navbar/>
      <div className="flex flex-1 overflow-hidden">
        <Sidebar/>
        <div className="flex-1 p-5 bg-[#E9ECF4]/30 overflow-auto">
          <div className="mb-[3%]">
            <h1 className="text-2xl font-bold">Analytics Dashboard</h1>
            <p className="text-gray-500">Real-time monitoring and insights</p>
          </div>
          <div className="flex w-full gap-10 mb-[5%]">
            <StatCard
            icon={WaterLoggings}
            stat={total}
            title="Total Hazards"/>
            <StatCard
            icon={Potholes}
            stat={rejected}
            title="Rejected"/>
            <StatCard
            icon={Fixed}
            stat={resolved}
            title="Resolved"/>
            <StatCard
            icon={ResponseTime}
            stat={pending}
            title="Pending"/>
            <StatCard
            icon={Growth}
            stat={inProgress}
            title="In Progress"/>
          </div>
          <DailyTrend/>
        </div>
      </div>
      
    </div>
  )
}

export default DashBoardPage