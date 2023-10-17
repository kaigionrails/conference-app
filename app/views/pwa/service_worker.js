const installHandler = async (event) => {
  console.info(event);
};

self.addEventListener("install", installHandler);
