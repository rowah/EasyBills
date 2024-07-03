defmodule EasyBillsWeb.InvoiceLive.FormComponent do
  use EasyBillsWeb, :live_component

  alias EasyBills.Billing

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Bill To</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        class="space-y-2"
        id="invoice-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:client_name]} type="text" label="Client name" />
        <.input field={@form[:client_email]} type="email" label="Client email" />
        <.input field={@form[:client_street_address]} type="text" label="Client address" />
        <div class="grid grid-cols-3 gap-4">
          <.input field={@form[:client_city]} type="text" label="City" />
          <.input field={@form[:client_postal_code]} type="text" label="Postal Code" />
          <.input field={@form[:client_country]} type="text" label="Country" />
        </div>
        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:due_at]} type="date" label="Invoice Date" />
          <.input field={@form[:terms]} type="text" label="Payment Terms" />
        </div>
        <.input field={@form[:description]} type="text" label="Project Description" />
        <h6>Item List</h6>
        <div class="cursor-pointer text-center bg-gray-200 p-2 rounded-2xl">
          <.icon name="hero-plus-small" /><span>Add New Item</span>
        </div>
        <%!-- <div>
          <.button>Discard</.button>
          <.button>Save as Draft</.button>
        </div> --%>
        <:actions>
          <.button phx-disable-with="Saving...">Save and Send</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{invoice: invoice} = assigns, socket) do
    changeset = Billing.change_invoice(invoice)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"invoice" => invoice_params}, socket) do
    changeset =
      socket.assigns.invoice
      |> Billing.change_invoice(invoice_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"invoice" => invoice_params}, socket) do
    save_invoice(socket, socket.assigns.action, invoice_params)
  end

  defp save_invoice(socket, :edit, invoice_params) do
    case Billing.update_invoice(socket.assigns.invoice, invoice_params) do
      {:ok, invoice} ->
        notify_parent({:saved, invoice})

        {:noreply,
         socket
         |> put_flash(:info, "Invoice updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_invoice(socket, :new, invoice_params) do
    case Billing.create_invoice(invoice_params) do
      {:ok, invoice} ->
        notify_parent({:saved, invoice})

        {:noreply,
         socket
         |> put_flash(:info, "Invoice created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
