function Features() {

  const features = [
    "Temperature Monitoring",
    "Humidity Monitoring",
    "Solar Energy Tracking",
    "Farmer Dashboard"
  ];

  return (

    <section className="py-16 text-center">

      <h2 className="text-3xl font-bold">
        Software Features
      </h2>

      <div className="grid grid-cols-2 gap-6 mt-8">

        {features.map((feature,index)=>(
          <div key={index} className="p-6 border rounded">

            {feature}

          </div>
        ))}

      </div>

    </section>
  );
}

export default Features;