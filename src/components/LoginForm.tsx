import React from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

const LoginForm: React.FC = () => {
  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    // Placeholder for form submission logic
    console.log("Form submitted");
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label
          htmlFor="email"
          className="block text-sm font-medium text-green-700"
        >
          Email
        </label>
        <Input
          type="email"
          id="email"
          name="email"
          required
          className="mt-1 block w-full"
        />
      </div>
      <div>
        <label
          htmlFor="password"
          className="block text-sm font-medium text-green-700"
        >
          Password
        </label>
        <Input
          type="password"
          id="password"
          name="password"
          required
          className="mt-1 block w-full"
        />
      </div>
      <Button
        type="submit"
        className="w-full flex justify-center bg-green-500 text-white hover:bg-green-600"
        variant="default"
      >
        Login
      </Button>
    </form>
  );
};

export default LoginForm;
