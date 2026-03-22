/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { Sun } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="bg-black text-white py-24 px-6 border-t border-white/10">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-16">
          {/* Brand */}
          <div className="space-y-6">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
                <Sun className="w-6 h-6 text-white" />
              </div>
              <span className="text-2xl font-heading font-extrabold text-white tracking-tighter">HELADRY</span>
            </div>
            <p className="text-white/40 text-sm leading-relaxed max-w-xs">
              Revolutionizing solar dehydration for a sustainable future. Empowering communities through innovation.
            </p>
          </div>

          {/* Links */}
          <div className="space-y-6">
            <h4 className="text-sm font-bold uppercase tracking-widest text-primary">Company</h4>
            <ul className="space-y-4 text-white/60 text-sm">
              <li><a href="#mission" className="hover:text-white transition-colors">Our Mission</a></li>
              <li><a href="#technology" className="hover:text-white transition-colors">Technology</a></li>
              <li><a href="#team" className="hover:text-white transition-colors">Team</a></li>
              <li><a href="#impact" className="hover:text-white transition-colors">Global Impact</a></li>
            </ul>
          </div>

          {/* Contact */}
          <div className="space-y-6">
            <h4 className="text-sm font-bold uppercase tracking-widest text-primary">Contact</h4>
            <ul className="space-y-4 text-white/60 text-sm">
              <li>info@heladry.com.lk</li>
              <li>+94 11 234 5678</li>
              <li>Colombo, Sri Lanka</li>
            </ul>
          </div>

          {/* Newsletter */}
          <div className="space-y-6">
            <h4 className="text-sm font-bold uppercase tracking-widest text-primary">Newsletter</h4>
            <div className="flex">
              <input 
                type="email" 
                placeholder="Email address" 
                className="bg-white/5 border border-white/10 rounded-l-full px-6 py-3 w-full focus:outline-none focus:border-primary transition-colors text-sm"
              />
              <button className="bg-primary hover:bg-primary-dark px-6 py-3 rounded-r-full transition-colors">
                →
              </button>
            </div>
          </div>
        </div>

        <div className="mt-24 pt-8 border-t border-white/5 flex flex-col md:flex-row justify-between items-center gap-6">
          <p className="text-white/20 text-xs">
            © {new Date().getFullYear()} Heladry. All rights reserved.
          </p>
          <div className="flex space-x-8 text-white/20 text-xs">
            <a href="#" className="hover:text-white transition-colors">Privacy Policy</a>
            <a href="#" className="hover:text-white transition-colors">Terms of Service</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
