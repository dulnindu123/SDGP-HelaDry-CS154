function Dashboard(){

  const temperature = 45;
  const humidity = 20;

  return(

    <section className="py-20 bg-gray-100 text-center">

      <h2 className="text-4xl font-bold text-green-700">
        Live Sensor Dashboard
      </h2>

      <p className="mt-3 text-gray-600">
        Real-time monitoring of the solar dehydrator
      </p>

      <div className="flex justify-center gap-12 mt-12">

        <div className="bg-white p-10 shadow-lg rounded-xl w-60">

          <h3 className="text-xl font-semibold">
            Temperature
          </h3>

          <p className="text-4xl mt-3 text-red-500">
            {temperature}°C
          </p>

        </div>

        <div className="bg-white p-10 shadow-lg rounded-xl w-60">

          <h3 className="text-xl font-semibold">
            Humidity
          </h3>

          <p className="text-4xl mt-3 text-blue-500">
            {humidity}%
          </p>

        </div>

      </div>

    </section>
  )
}

export default Dashboard