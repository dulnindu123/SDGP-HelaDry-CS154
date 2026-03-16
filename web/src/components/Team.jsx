function Team() {

  const team = [
    {name:"Aman", role:"Frontend Developer", image:"/Aman.jpeg"},
    {name:"Asjath", role:"IoT Developer", image:"/Asjath.jpeg"},
    {name:"Dulnindu", role:"Backend Developer", image:"/Dulnindu.jpeg"},
    {name:"Lorshan", role:"Research Lead", image:"/Lorshan.jpeg"},
    {name:"Drian", role:"Research Lead", image:"/Drian.jpeg"},
    {name:"Wethum", role:"Research Lead", image:"/Wethum.jpeg"},



  ];

  return (

    <section className="py-20 bg-gray-100 text-center">

      <h2 className="text-4xl font-bold text-green-700">
        Meet Our Team
      </h2>

      <p className="mt-3 text-gray-600">
        The innovators behind the HelaDry Solar Dehydrator
      </p>

      <div className="flex justify-center gap-10 mt-12 flex-wrap">

        {team.map((member,index)=>(
          
          <div
            key={index}
            className="bg-white shadow-lg rounded-xl p-6 w-60 hover:scale-105 transition duration-300"
          >

            <img
              src={member.image}
              alt={member.name}
              className="w-32 h-32 object-cover rounded-full mx-auto"
            />

            <h3 className="mt-4 text-xl font-semibold">
              {member.name}
            </h3>

            <p className="text-gray-500">
              {member.role}
            </p>

          </div>

        ))}

      </div>

    </section>
  );
}

export default Team;