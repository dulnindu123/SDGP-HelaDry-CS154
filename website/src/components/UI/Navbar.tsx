/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { motion, useScroll, useTransform } from 'motion/react';
import { useEffect, useState } from 'react';
import { Sun } from 'lucide-react';

/**
 * Navbar: Fades in at the top once the zoom reaches the "Sky" frame.
 * High-contrast White/Green layout.
 */
export default function Navbar() {
  const [isVisible, setIsVisible] = useState(false);
  const [threshold, setThreshold] = useState(0);
  const { scrollY } = useScroll();

  useEffect(() => {
    // The hero section is 500vh, so we only show the navbar after that
    const handleScroll = () => {
      const threshold = 400 * window.innerHeight / 100; // End of pinning
      if (window.scrollY > threshold) {
        setIsVisible(true);
      } else {
        setIsVisible(false);
      }
    };

    window.addEventListener('scroll', handleScroll);
    handleScroll(); // Initial check
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Fade in the navbar after the hero sequence ends
  const opacity = useTransform(scrollY, [350 * window.innerHeight / 100, 400 * window.innerHeight / 100], [0, 1]);

  return (
    <motion.nav
      style={{ opacity }}
      className={`fixed top-0 left-0 right-0 z-[5000] px-6 py-4 transition-all duration-500 ${
        isVisible ? 'bg-white/80 backdrop-blur-md shadow-sm' : 'bg-transparent'
      }`}
    >
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        {/* Logo */}
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
            <Sun className="w-6 h-6 text-white" />
          </div>
          <span className="text-2xl font-heading font-extrabold text-primary tracking-tighter">HELADRY</span>
        </div>

        {/* Navigation Links */}
        <div className="hidden md:flex items-center space-x-10">
          {['Mission', 'Technology', 'Impact', 'Team', 'Contact'].map((item) => (
            <a
              key={item}
              href={`#${item.toLowerCase()}`}
              className="text-sm font-body font-semibold text-gray-700 hover:text-primary transition-colors uppercase tracking-widest"
            >
              {item}
            </a>
          ))}
        </div>

        {/* CTA Button */}
        <button className="bg-primary text-white px-6 py-3 rounded-full font-bold text-sm hover:bg-primary-dark transition-all transform hover:scale-105">
          Get Started
        </button>
      </div>
    </motion.nav>
  );
}
