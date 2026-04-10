import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useSelector } from 'react-redux';

function DailyTrend() {
    const Sunday = useSelector(state => state.dailyData.Sunday) ?? 0;
    const Monday = useSelector(state => state.dailyData.Monday) ?? 0;
    const Tuesday = useSelector(state => state.dailyData.Tuesday) ?? 0;
    const Wednesday = useSelector(state => state.dailyData.Wednesday) ?? 0;
    const Thursday = useSelector(state => state.dailyData.Thursday) ?? 0;
    const Friday = useSelector(state => state.dailyData.Friday) ?? 0;
    const Saturday = useSelector(state => state.dailyData.Saturday) ?? 0;

    const data = [
        { day: 'Sun', count: Sunday },
        { day: 'Mon', count: Monday },
        { day: 'Tue', count: Tuesday },
        { day: 'Wed', count: Wednesday },
        { day: 'Thu', count: Thursday },
        { day: 'Fri', count: Friday },
        { day: 'Sat', count: Saturday },
    ];

  return (
    <div style={{ width: '420px', height: '320px' }}>
        <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data} margin={{ top: 5, right: 20, left: 0, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="day" />
            <YAxis />
            <Tooltip />
            <Line type="monotone" dataKey="count" stroke="#ef4444"
              strokeWidth={2} dot={{ r: 5, fill: '#ef4444' }} />
        </LineChart>
    </ResponsiveContainer>
    </div>
  )
}

export default DailyTrend