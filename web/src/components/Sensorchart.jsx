import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer
} from "recharts";

function SensorChart(){

  const data = [
    {time:"10:00", temp:40, humidity:25},
    {time:"11:00", temp:42, humidity:23},
    {time:"12:00", temp:45, humidity:21},
    {time:"13:00", temp:47, humidity:20},
    {time:"14:00", temp:48, humidity:18},
  ];

  return(

    <section className="py-20 text-center">

      <h2 className="text-4xl font-bold text-green-700">
        Drying Process Monitoring
      </h2>

      <div className="mt-12 h-80 w-4/5 mx-auto">

        <ResponsiveContainer>

          <LineChart data={data}>

            <CartesianGrid strokeDasharray="3 3" />

            <XAxis dataKey="time"/>

            <YAxis/>

            <Tooltip/>

            <Line type="monotone" dataKey="temp" stroke="#ff4d4d" />

            <Line type="monotone" dataKey="humidity" stroke="#4da6ff" />

          </LineChart>

        </ResponsiveContainer>

      </div>

    </section>
  )
}

export default SensorChart