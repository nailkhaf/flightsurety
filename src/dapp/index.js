import DOM from "./dom";
import Contract from "./contract";
import "./flightsurety.css";

(async () => {

  let contract = new Contract("localhost", async () => {
    // Read transaction
    contract.isPaused((error, result) => {
      result = !result;
      console.log(error, result);
      display("Operational Status", "Check if contract is operational", [
        {label: "Operational Status", error: error, value: result}
      ]);
    });

    // User-submitted transaction
    DOM.elid("submit-oracle").addEventListener("click", () => {
      const option = DOM.elid("flight-number-selector").value;
      const flight = contract.getFlights()[parseInt(option)];
      // Write transaction
      contract.fetchFlightStatus(flight, (error, result) => {
        display("Oracles", "Trigger oracles", [
          {
            label: "Fetch Flight Status",
            error: error,
            value: result.flight + " " + result.timestamp
          }
        ]);
      });
    });

    DOM.elid("buy-insurance").addEventListener("click", async () => {
      const option = DOM.elid("flight-number-selector").value;
      const flight = contract.getFlights()[parseInt(option)];

      try {
        await contract.buyInsurance(flight)
        alert(`Buying insurance success.`);
      } catch(e) {
        alert(`Buying insurance is failed. ${e.message}`);
      }
    });

    DOM.elid("payout-insurance").addEventListener("click", async () => {
      const option = DOM.elid("flight-number-selector").value;
      const flight = contract.getFlights()[parseInt(option)];

      try {
        await contract.payoutInsurance(flight)
        alert(`Payout insurance success.`);
      } catch(e) {
        alert(`Payout insurance is failed. ${e.message}`);
      }
    });

    // User-submitted transaction
    DOM.elid("submite-register-flights").addEventListener("click", async () => {
      const registered = await contract.isAirlineRegistered();
      if (!registered) {
        alert("You are not registered airline, can't create test flights");
        return;
      }

      try {
        await contract.registerTestFlights();

        displayFlights(DOM.elid("flight-number-selector"), contract.getFlights());

        alert("Test flights are registered");
      } catch(e) {
        alert(`Registration of test flights is failed. ${e.message}`);
      }
    });

    await contract.authorizeApp();

    displayFlights(DOM.elid("flight-number-selector"), contract.getFlights());

    setTimeout(async () => {
      await contract.listenFlightStatus((err, res) => {

        display("Oracles", "Listen oracles", [
          {
            label: "Flight Status Info",
            error: err,
            value: `${res.returnValues.flight}:${res.returnValues.status}`
          }
        ]);
      })
    }, 1000)

  });
})();

function display(title, description, results) {
  let displayDiv = DOM.elid("display-wrapper");
  let section = DOM.section();
  section.appendChild(DOM.h2(title));
  section.appendChild(DOM.h5(description));
  results.map(result => {
    let row = section.appendChild(DOM.div({className: "row"}));
    row.appendChild(DOM.div({className: "col-sm-4 field"}, result.label));
    row.appendChild(
      DOM.div(
        {className: "col-sm-8 field-value"},
        result.error ? String(result.error) : String(result.value)
      )
    );
    section.appendChild(row);
  });
  displayDiv.append(section);
}

function displayFlights(select, flights) {
  console.log(`#displayFlights flights=${JSON.stringify(flights)}`)

  for (var i = 0; i < flights.length; i++) {
    const option = DOM.option();
    option.text = flights[i].name;
    option.value = i;
    select.appendChild(option);
  }
}
