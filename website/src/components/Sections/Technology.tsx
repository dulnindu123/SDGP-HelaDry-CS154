/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { motion } from 'motion/react';
import { Sun, Thermometer, Leaf } from 'lucide-react';

export default function Technology() {
  const features = [
    {
      title: "Advanced Solar Panels",
      description: "High-efficiency photovoltaic cells that capture maximum energy even in low-light conditions.",
      icon: <Sun className="w-6 h-6 text-white" />,
    },
    {
      title: "Smart Dehydration",
      description: "Automated temperature and humidity control for optimal drying results every time.",
      icon: <Thermometer className="w-6 h-6 text-white" />,
    },
    {
      title: "Eco-Friendly Design",
      description: "Constructed with sustainable materials and zero-emission operations.",
      icon: <Leaf className="w-6 h-6 text-white" />,
    },
    ];

  return (
    <section id="technology" className="relative z-10 bg-primary py-32 px-6 overflow-hidden">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-24 items-center">
          {/* Text Content */}
          <motion.div 
            initial={{ opacity: 0, y: 50 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: "easeOut" }}
            viewport={{ once: true }}
            className="space-y-10"
          >
            <div className="space-y-4">
              <span className="text-white/60 font-bold tracking-[0.3em] uppercase text-xs">Our Technology</span>
              <h2 className="text-6xl md:text-8xl font-heading text-white leading-[0.9] tracking-tighter">
                Innovation <br />
                <span className="text-white/60 italic">At Scale.</span>
              </h2>
            </div>
            
            <p className="text-xl text-white/80 font-body leading-relaxed max-w-xl">
              Our solar dehydrators are built with precision engineering and cutting-edge technology to ensure maximum efficiency and sustainability.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-8 pt-6">
              {features.map((feature, index) => (
                <div key={index} className="space-y-4">
                  <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center text-2xl">
                    {feature.icon}
                  </div>
                  <h3 className="text-xl font-heading text-white font-bold">{feature.title}</h3>
                  <p className="text-white/60 text-sm leading-relaxed">{feature.description}</p>
                </div>
              ))}
            </div>
          </motion.div>

          {/* Visual / Image */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 1, ease: "easeOut" }}
            viewport={{ once: true }}
            className="relative"
          >
            <div className="aspect-square rounded-[3rem] overflow-hidden shadow-2xl relative z-10">
              <img 
                src="assets/Cover.png" 
                alt="Solar Technology" 
                className="w-full h-full object-cover"
                referrerPolicy="no-referrer"
              />
            </div>
            
            {/* Background Decorative Element */}
            <div className="absolute -top-20 -right-20 w-64 h-64 bg-white/5 rounded-full blur-3xl" />
            <div className="absolute -bottom-20 -left-20 w-96 h-96 bg-white/10 rounded-full blur-3xl" />
          </motion.div>
        </div>
      </div>
    </section>
  );
}
