import React from "react";

const Footer: React.FC = () => {
  return (
    <footer className="bg-gradient-to-r from-devdark via-black to-devdark text-gold py-8 mt-12 shadow-inner font-mono">
      <div className="container mx-auto flex flex-col md:flex-row items-center justify-between px-4">
        <div className="mb-2 md:mb-0">
          <p className="text-sm font-bold text-gold drop-shadow-gold">
            © {new Date().getFullYear()} DevCON. All rights reserved.
          </p>
          <p className="text-xs mt-1 text-gold/80 font-mono">
            Connect with developers worldwide and build amazing projects
            together.
          </p>
        </div>
        <div className="flex gap-4">
          <a
            href="https://github.com/"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="GitHub"
            className="hover:text-gold transition"
          >
            <svg
              width="24"
              height="24"
              fill="currentColor"
              className="inline-block align-middle"
              viewBox="0 0 24 24"
            >
              <path d="M12 .5C5.73.5.5 5.73.5 12c0 5.08 3.29 9.39 7.86 10.91.58.11.79-.25.79-.56v-2.02c-3.2.7-3.87-1.54-3.87-1.54-.53-1.34-1.3-1.7-1.3-1.7-1.06-.72.08-.71.08-.71 1.17.08 1.79 1.2 1.79 1.2 1.04 1.78 2.73 1.27 3.4.97.11-.75.41-1.27.75-1.56-2.56-.29-5.26-1.28-5.26-5.7 0-1.26.45-2.29 1.19-3.09-.12-.29-.52-1.45.11-3.02 0 0 .97-.31 3.18 1.18a11.1 11.1 0 012.9-.39c.98.01 1.97.13 2.9.39 2.2-1.49 3.17-1.18 3.17-1.18.63 1.57.23 2.73.11 3.02.74.8 1.19 1.83 1.19 3.09 0 4.43-2.7 5.41-5.27 5.7.42.36.8 1.08.8 2.18v3.23c0 .31.21.67.8.56A10.52 10.52 0 0023.5 12C23.5 5.73 18.27.5 12 .5z" />
            </svg>
          </a>
          <a
            href="https://twitter.com/"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Twitter"
            className="hover:text-gold transition"
          >
            <svg
              width="24"
              height="24"
              fill="currentColor"
              className="inline-block align-middle"
              viewBox="0 0 24 24"
            >
              <path d="M24 4.557a9.93 9.93 0 01-2.828.775 4.932 4.932 0 002.165-2.724c-.951.564-2.005.974-3.127 1.195a4.916 4.916 0 00-8.38 4.482C7.691 8.094 4.066 6.13 1.64 3.161c-.542.929-.855 2.01-.855 3.17 0 2.188 1.115 4.117 2.823 5.254a4.904 4.904 0 01-2.229-.616c-.054 2.281 1.581 4.415 3.949 4.89a4.936 4.936 0 01-2.224.084c.627 1.956 2.444 3.377 4.6 3.417A9.867 9.867 0 010 21.543a13.94 13.94 0 007.548 2.212c9.058 0 14.009-7.513 14.009-14.009 0-.213-.005-.425-.014-.636A10.025 10.025 0 0024 4.557z" />
            </svg>
          </a>
          <a
            href="mailto:contact@devcon.com"
            aria-label="Email"
            className="hover:text-gold transition"
          >
            <svg
              width="24"
              height="24"
              fill="currentColor"
              className="inline-block align-middle"
              viewBox="0 0 24 24"
            >
              <path d="M12 13.065l-11.99-7.99A1.001 1.001 0 012 4h20a1.001 1.001 0 011.99 1.075l-11.99 7.99zm-11.99 2.01V20a2 2 0 002 2h16a2 2 0 002-2v-4.925l-9.99 6.66a1.001 1.001 0 01-1.02 0l-9.99-6.66z" />
            </svg>
          </a>
        </div>
      </div>
    </footer>
  );
};

export default Footer;

export default Footer;
