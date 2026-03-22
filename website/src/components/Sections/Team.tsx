/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { motion } from 'motion/react';

export default function Team() {
  const team = [
    {
      name: "Dulnindu Saranga",
      role: "Lead Engineer and Firmware Developer",
      image: "TeamAssets/Dulnindu.jpeg",
    },
    {
      name: "Wethum Kiriwattuduwa",
      role: "BackendDeveloper",
      image: "TeamAssets/Wethum.jpeg",
    },
    {
      name: "Asjath Ahamed",
      role: "Frontend Developer",
      image: "TeamAssets/Asjath.jpeg",
    },
    {
      name: "Drian Logaeswaran",
      role: "Developer and QA",
      image: "TeamAssets/Drian.jpeg",
    },
    {
      name: "Kabilesh K",
      role: "Frontend Developer and QA",
      image: "TeamAssets/logo.png",
    },
    {
      name: "Seyed Aman Zahir",
      role: " Backend Developer",
      image: "TeamAssets/Aman.jpeg",
    },
    {
      name: "Lorshan Harith Ravichandran",
      role: " Web Developer and QA",
      image: "TeamAssets/Lorshan.jpeg",
    },
  ];

  return (
    <section id="team" className="relative z-10 bg-white py-32 px-6 overflow-hidden">
      <div className="max-w-7xl mx-auto">
        <div className="space-y-16">
          <div className="text-center space-y-4">
            <span className="text-primary font-bold tracking-[0.3em] uppercase text-xs">The Visionaries</span>
            <h2 className="text-6xl md:text-8xl font-heading text-black leading-tight tracking-tighter">
              Meet Our <span className="text-primary italic">Team.</span>
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
            {team.map((member, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="group relative"
              >
                <div className="aspect-[3/4] rounded-3xl overflow-hidden shadow-xl">
                  <img 
                    src={member.image} 
                    alt={member.name} 
                    className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                    referrerPolicy="no-referrer"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 flex flex-col justify-end p-8">
                    <h3 className="text-2xl font-heading text-white font-bold">{member.name}</h3>
                    <p className="text-white/70 font-body">{member.role}</p>
                  </div>
                </div>
                <div className="mt-6 text-center group-hover:opacity-0 transition-opacity duration-500">
                  <h3 className="text-xl font-heading text-black font-bold">{member.name}</h3>
                  <p className="text-gray-500 font-body">{member.role}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

