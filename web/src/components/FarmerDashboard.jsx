function FarmerDashboard(){

  return(

    <section className="py-20 bg-gray-100 text-center">

      <h2 className="text-4xl font-bold text-green-700">
        Farmer Dashboard
      </h2>

      <div className="flex justify-center gap-10 mt-12">

        <div className="bg-white shadow-lg p-8 rounded-xl w-60">

          <h3 className="text-xl font-semibold">
            Crops Drying
          </h3>

          <p className="text-3xl mt-3 text-green-600">
            3 Batches
          </p>

        </div>

        <div className="bg-white shadow-lg p-8 rounded-xl w-60">

          <h3 className="text-xl font-semibold">
            Solar Efficiency
          </h3>

          <p className="text-3xl mt-3 text-yellow-500">
            85%
          </p>

        </div>

        <div className="bg-white shadow-lg p-8 rounded-xl w-60">

          <h3 className="text-xl font-semibold">
            Drying Status
          </h3>

          <p className="text-3xl mt-3 text-blue-500">
            Active
          </p>

        </div>

      </div>

    </section>
  )
}

export default FarmerDashboard