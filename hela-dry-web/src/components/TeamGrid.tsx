import { useState } from 'react';

const TEAM_MEMBERS = [
    {
        name: "W.K. Dulnindu Saranga",
        role: "Project Leader & IoT Systems Architect",
        description: "Leads the full project lifecycle, from requirement engineering to system integration. Oversees technical decision-making, ensures all subsystems work together seamlessly, and manages coordination between the software, hardware, and UI/UX teams.",
        image: "Dulnindu.jpeg"
    },
    {
        name: "K.D.W.K. Kiriwattuduwa",
        role: "Hardware Design & Embedded Systems Engineer",
        description: "Specialises in circuit design, microcontroller programming, and hardware testing. Responsible for ensuring stable sensor integration, power management, and the physical system's operational reliability.",
        image: "Wethum.jpeg" // using original name from original HTML
    },
    {
        name: "B.M. Asjath Ahamed",
        role: "Software Developer & Algorithm Designer",
        description: "Focuses on core application logic, system optimisation, and functional testing. Contributes to creating efficient workflows, backend processes, and data-driven decision components within the project.",
        image: "Asjath.jpeg"
    },
    {
        name: "L.G. Drian",
        role: "UI/UX Designer & Front-End Interface Developer",
        description: "Designs intuitive user interfaces and user flows for smooth system interaction. Ensures the visual experience is clean, responsive, and perfectly aligned with the project's theme and branding guidelines.",
        image: "Drain.jpeg" // using original name from original HTML
    },
    {
        name: "Kabilesh K",
        role: "Mechanical Design & Technical Documentarian",
        description: "Works on mechanical housing, mounting structures, and supportive components. Produces high-quality documentation including diagrams, assembly notes, and operational guides for the project.",
        image: "" // Empty image string triggers placeholder
    },
    {
        name: "Seyed Aman Zahir",
        role: "Web Application Developer & Backend Engineer",
        description: "Responsible for the full design and development of the web dashboard interface. Manages backend integrations, database connections (Firebase), and supports hardware–software bridging for the smart machine components.",
        image: "Aman.jpeg"
    },
    {
        name: "Lorshan Harith Ravichandran",
        role: "Quality Assurance & Deployment Engineer",
        description: "Oversees testing, debugging, and validation across both hardware and software modules. Ensures that the final system meets performance standards and assists with deployment, calibration, and real-environment verification.",
        image: "Lorshan.jpeg"
    }
];

export default function TeamGrid() {
  return (
    <section className="py-24 bg-transparent max-w-7xl mx-auto px-6 lg:px-8 z-10 relative">
      <div className="mx-auto max-w-2xl text-center mb-16">
        <h2 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-5xl">Meet Team CS-154</h2>
        <p className="mt-4 text-lg/8 text-gray-600">The innovative minds behind the smart solar dehydrator.</p>
      </div>

      <div className="mx-auto grid max-w-2xl grid-cols-1 gap-x-8 gap-y-16 sm:grid-cols-2 lg:mx-0 lg:max-w-none lg:grid-cols-3">
        {TEAM_MEMBERS.map((member, idx) => (
          <article key={idx} className="flex max-w-xl flex-col items-start justify-between bg-white/80 backdrop-blur-md rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-lg transition-shadow duration-300">
            <div className="flex items-center gap-x-4 mb-6">
                {member.image ? (
                    <img 
                      src={`/${member.image}`} 
                      alt={member.name} 
                      className="h-16 w-16 rounded-full bg-gray-50 object-cover border-2 border-forest-green"
                    />
                ) : (
                    <div className="h-16 w-16 rounded-full bg-forest-light text-white flex items-center justify-center text-2xl font-bold border-2 border-forest-green">
                        {member.name.charAt(0)}
                    </div>
                )}
              <div className="text-sm/6">
                <p className="font-semibold text-gray-900">
                  <span className="absolute inset-0" />
                  {member.name}
                </p>
                <p className="text-forest-green font-medium">{member.role}</p>
              </div>
            </div>
            
            <div className="group relative">
              <p className="mt-2 line-clamp-4 text-sm/6 text-gray-600 group-hover:line-clamp-none transition-all duration-300">
                {member.description}
              </p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
