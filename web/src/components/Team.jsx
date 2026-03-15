function Team() {

  const team = [
    {name:"Aman", image:"/Aman.jpeg"},
    {name:"Asjath", image:"/Asjath.jpeg"},
    {name:"Dulnindu", image:"/Dulnindu.jpeg"},
    {name:"Lorshan", image:"/Lorshan.jpeg"},
    {name:"Drian", image:"/Drian.jpeg"},
    {name:"Wethum", image:"/Wethum.jpeg"},
    {name:"Kabilesh", image:"/Kabilesh.jpeg"},
  ];

  return (

    <section className="py-16 text-center">

      <h2 className="text-3xl font-bold">Our Team</h2>

      <div className="flex justify-center gap-10 mt-10">

        {team.map((member,index)=>(
          
          <div key={index}>

            <img
              src={member.image}
              className="w-32 h-32 rounded-full"
            />

            <p>{member.name}</p>

          </div>

        ))}

      </div>

    </section>
  );
}

export default Team;